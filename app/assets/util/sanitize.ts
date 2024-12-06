/**
 * Sanitizes a given string by replacing all characters that are not
 * alphanumeric, hyphens, underscores, or periods with an underscore.
 *
 * @param name - The string to be sanitized.
 * @returns The sanitized string.
 */
const sanitize = (name: string) => name.replace(/[^-a-zA-Z0-9_.]+/g, '_');

export default sanitize;
