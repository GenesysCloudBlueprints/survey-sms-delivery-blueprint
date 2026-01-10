terraform {
  required_providers {
    genesyscloud = {
      source  = "mypurecloud/genesyscloud"
      version = "1.51.0"
    }
  }
}

provider "genesyscloud" {
  sdk_debug = true
}

module "data_actions" {
    source = "../data-actions"
    client_id = var.client_id
    client_secret = var.client_secret
}

resource "null_resource" "deploy_archy_flow" {
    depends_on = [
      module.data_actions,
    ]
    provisioner "local-exec" {
        command = "  archy publish --forceUnlock --file SendSurvey_v1-0.yaml --clientId $GENESYSCLOUD_OAUTHCLIENT_ID --clientSecret $GENESYSCLOUD_OAUTHCLIENT_SECRET --location $GENESYSCLOUD_ARCHY_LOCATION  --overwriteResultsFile --resultsFile results.json "
    }
}

data "genesyscloud_flow" "sendsurvey_flow" {
    depends_on = [
        module.data_actions,
        null_resource.deploy_archy_flow,
    ]
    name = "SendSurvey"
}

resource "genesyscloud_architect_ivr" "sendsurvey_ivr" {
    name               = "SendSurvey"
    description        = "Send Survey by SMS"
    open_hours_flow_id = data.genesyscloud_flow.sendsurvey_flow.id
}