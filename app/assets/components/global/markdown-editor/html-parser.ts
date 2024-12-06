import MarkdownIt from 'markdown-it';

const md = new MarkdownIt({ linkify: true });

// Helper functions to override renderers
// See https://github.com/markdown-it/markdown-it/blob/master/docs/examples/renderer_rules.md#reusing-existing-rules
const proxy: MarkdownIt.Renderer.RenderRule = (
  tokens,
  idx,
  options,
  env,
  self,
) => self.renderToken(tokens, idx, options);

const defaultImageRenderer = md.renderer.rules.image || proxy;
const defaultLinkRenderer = md.renderer.rules.link_open || proxy;

// Files and images inserted in the editor will start with upload:/ or s3:/, depending
// on whether they have already been saved. Here we modify the href value (for files) or
// src value (for images) with the right url so that the preview works fine.
const overrideRenderer =
  (
    tag: string,
    uploadUrl: string,
    savedUrlsMapping: { [key: string]: string },
  ): MarkdownIt.Renderer.RenderRule =>
  (tokens, idx, options, env, self) => {
    const index = tokens[idx].attrIndex(tag === 'image' ? 'src' : 'href');

    if (index !== -1 && tokens[idx].attrs?.[index]?.[1]) {
      const value = tokens[idx].attrs![index][1] as string;
      const modifiedTokens = [...tokens]; // Create a copy of tokens
      if (value.includes('s3:/')) {
        modifiedTokens[idx].attrs![index][1] = savedUrlsMapping[value] || value;
      } else {
        modifiedTokens[idx].attrs![index][1] = value.replace(
          'upload:/',
          `${uploadUrl}/uploads`,
        );
      }
      return tag === 'image'
        ? defaultImageRenderer(modifiedTokens, idx, options, env, self)
        : defaultLinkRenderer(modifiedTokens, idx, options, env, self);
    }
    return tag === 'image'
      ? defaultImageRenderer(tokens, idx, options, env, self)
      : defaultLinkRenderer(tokens, idx, options, env, self);
  };

const parseMarkdownToHTML = (
  content: string,
  uploadUrl: string,
  savedUrlsMapping: { [key: string]: string },
) => {
  if (uploadUrl && savedUrlsMapping) {
    md.renderer.rules.image = overrideRenderer(
      'image',
      uploadUrl,
      savedUrlsMapping,
    );
    md.renderer.rules.link_open = overrideRenderer(
      'link',
      uploadUrl,
      savedUrlsMapping,
    );
  }
  return md.render(content);
};

export default parseMarkdownToHTML;
