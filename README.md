# entra-opa-jwt

## Thank you!
To @pvsone for creating the original example repo. Unfortunately the original JWKS sample service appears to be down. And since my usecase requires authenticating with Entra anyway I figure Ill detail the process here.

## Overview

An example policy showing JSON Web Key Sets (JWKS) based validation of JSON Web Tokens (JWT) using the OPA [Token Verification](https://www.openpolicyagent.org/docs/latest/policy-reference/#token-verification) built-in functions.  

This example uses Microsoft Entra to validate a jwt. The jwks keys url should look like: `https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys`. Your organizations full `.well-known` endpoint can be found at a url like `https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration`

Full details on how JWT Validation works can be found [here](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens#validate-the-signature). But that is not necessary because the rego method [`io.jwt.decode_verify`](https://www.openpolicyagent.org/docs/latest/policy-reference/#builtin-tokens-iojwtdecode_verify) handles it for us.

The organization of the policy rules and data will follow the OPA [Bundle File Format](https://www.openpolicyagent.org/docs/latest/management-bundles/#bundle-file-format)

## Prerequisites

- [Install OPA](https://www.openpolicyagent.org/docs/latest/#running-opa)
- [Install jq](https://jqlang.github.io/jq/download/) to  your workstation. I used `winget install jqlang.jq`.
- Access to a Microsoft Entra ID tenant with ability to create App Registrations and Users.

## Setup

To simplify this tutorial, we will create an Application with the [Resource admin Password Credential Flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth-ropc) enabled.

### Create App Registration

1. Log into Azure Portal, navigating to `Microsoft Entra ID` > `App Registrations`
2. Click `+ New Registration`
3. Enter the Name: `entra-opa-jwt`, click REGISTER
4. Navigate to Authentication
5. At the bottom, flip the option `Enable the following mobile and desktop flows:` to `yes`. Click Save.
6. Navigate to `App Roles`
7. Add the following two roles: `admin`, and `user`.
   1. Click `+ Create app role`.
   2. Enter the role name `admin` or `user` respectively.
   3. Select `Both` Allowed Member Types
   4. Enter the value `admin` or `user` respectively.
   5. Enter the description `admin` or `user` respectively.
   6. Click `Apply`
8. Navigate to `Manifest`
9. Change `accessTokenAcceptedVersion` from `null` to `2`
10. Click `Save`

### Create Users

1. In Microsoft Entra ID, Navigate to `Users`
2. Add the following two users: `entra-opa-jwt-admin`, `entra-opa-jwt-user`
   1. Click `+ New user` > `Create new user`.
   2. Enter `entra-opa-jwt-admin` or `entra-opa-jwt-user` for the principal user name respectively
   3. Enter `entra-opa-jwt-admin` or `entra-opa-jwt-user` for the display name respectively
   4. Copy and keep the password
   5. Click `Review + create`.
   6. Click `Create`
3. Ensure MFA is not enabled for these users. (I did this by disabling Security Defaults under Entra Permissions for my test tenant.)

### Assign user roles

1. In Microsoft Entra ID, Navigate to `Enterprise Applications`.
2. Click into the `entra-opa-jwt` app
3. Navigate to `Users and groups`
4. Add role assignments for each of the two users and roles created in the previous steps
   1. Click `+ Add user/group`
   2. Select the `Users` Box, check either the `entra-opa-jwt-admin` or `entra-opa-jwt-user` user respectively
   3. Click `Select`
   4. Select the `Select a role*` box, check the `admin` or `user` role appropriate to the user
   5. Click `Assign`
5. Navigate to `Security/Permissions`
6. Click `Grant Admin Consent for...`

### Generate jwks data and input token

```bash
tenantid="{your tenant id}"
clientid="{your app registration client id}"
username="entra-opa-jwt-admin@{your-tenant}.onmicrosoft.com"
password="{entra-opa-jwt-admin password}"
issuer="https://login.microsoftonline.com/$tenantid/v2.0"

curl --location "https://login.microsoftonline.com/$tenantid/discovery/v2.0/keys" > bundle/jwks/data.json
curl --location "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-urlencode "client_id=$clientid" \
--data-urlencode "scope=$clientid/.default" \
--data-urlencode "username=$username" \
--data-urlencode "password=$password" \
--data-urlencode "grant_type=password" | jq --arg iss $issuer --arg aud $clientid '{jwt:.access_token, iss: $iss, aud: $aud, }' > input.json
```

## Exercise the Policy

The policy file [bundle/rules/rules.rego](bundle/rules/rules.rego) contains example usage of built-in functions for JWT verification and decoding.  Assuming the `data.json` and `input.json` files have been placed in the correct directories (per the above commands), you will be able to evaluate the policy rules and see valid results.

```bash
# Verify the Signature only
opa eval -b ./bundle -i input.json data.rules.verify_output
# result will contain `true`

# Decode the JWT only
opa eval -b ./bundle -i input.json data.rules.decode_output
# result will contain the decoded token as JSON

# Decode AND Verify
opa eval -b ./bundle -i input.json data.rules.decode_verify_output
# result will contain `true` AND the decoded token as JSON
```
