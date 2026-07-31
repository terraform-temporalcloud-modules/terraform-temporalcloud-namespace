provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

locals {
  name = "ex-${basename(path.cwd)}"
}

################################################################################
# A self-signed CA, so this example runs with no external setup
#
# Temporal Cloud only needs the CA certificate — it never sees the private key.
# In production this CA is issued by your PKI, and `accepted_client_ca` is fed
# from that instead of generated here.
################################################################################

resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  is_ca_certificate     = true
  validity_period_hours = 8760 # 1 year
  set_subject_key_id    = true

  subject {
    common_name  = "${local.name}-ca"
    organization = "Example Org"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

################################################################################
# mTLS namespace
################################################################################

module "namespace" {
  source = "../../"

  name           = local.name
  regions        = ["aws-us-east-1"]
  retention_days = 7

  # The provider expects the CA bundle Base64-encoded.
  accepted_client_ca = base64encode(tls_self_signed_cert.ca.cert_pem)

  # Without filters, any certificate signed by the CA above may connect. Filters
  # narrow that to certificates whose distinguished name matches at least one
  # entry — a connection is accepted if ANY filter matches.
  certificate_filters = [
    {
      common_name         = "worker.example.com"
      organization        = "Example Org"
      organizational_unit = "platform"
    },
  ]

  tags = {
    Example   = local.name
    Terraform = "true"
    AuthMode  = "mtls"
  }
}
