package rules

# Get the JWT value from the query `input`
jwt := input.jwt
iss := input.iss
aud := input.aud

# Serialize the JWKS JSON data to a string
jwks_keys := json.marshal(data.bundle.jwks)

# Decode the JWT (without verification)
decode_output := io.jwt.decode(jwt)

# Define the constraints to use with `decode_verify`
constraints := {
  "cert": jwks_keys, 
  "iss": iss,
  "aud": aud,
  "time": time.now_ns()
}
decode_verify_output := io.jwt.decode_verify(jwt, constraints)

# Note that `aud` must be provided, since it is present in the token payload claims.
# If `aud` is omitted from the constraints, then it *must* be absent from the claims too.

# Specifying time as `time.now_ns()` is redundant as the current time is the default value,
# but this is left in the example for explicit demostration of the `time` constraint.
