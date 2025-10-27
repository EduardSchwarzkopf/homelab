

resource "nginxproxymanager_certificate_letsencrypt" "lan_schwarzkopf_center" {
  domain_names = ["*.lan.schwarzkopf.center"]

  letsencrypt_email   = "eduard@schwarzkopf.center"
  letsencrypt_agree   = true
  propagation_seconds = 120

  dns_challenge = true
  dns_provider  = "plesk"
  dns_provider_credentials = templatefile(
    "${path.module}/credentials.plesk.tpl",
    {
      plesk_username = var.plesk_username
      plesk_password = var.plesk_password
      plesk_api_url  = var.plesk_api_url
    }
  )
}
