# Chatbot Authentication Flow

The chatbot bridge API allows external systems implementing a chatbot to retrieve information
on behalf of authenticated users. It is safe to assume that such external systems have no
knowledge on the internal user ID in Xikolo, but share a common user ID when connecting via
SSO, e.g. the SAML NameID, also referenced as `uid`.

The chatbot bridge API provides an authentication endpoint that issues a signed token for a
Xikolo user, when requesting such with a uid. With this token, further information about the
Xikolo user can be retrieved. Also, users can be enrolled to or unenrolled from a course.

Please note that the user token may be of limited lifetime. We recommend to request a fresh
token at the beginning of each conversation.

Access to the authentication endpoint requires a shared secret as Bearer token (needs to be
exchanged via a seperate, secure communication channel).

![Sequence diagram for authentication flow](https://i.imgur.com/QfCDuAU.png)
