terraform {
  required_providers {
    genesyscloud = {
      source = "genesys.com/mypurecloud/genesyscloud"
      version = "0.1.0"
    }
  }
}

provider "genesyscloud" {
  sdk_debug = true
}

module "integration" {
    source = "git::https://github.com/GenesysCloudDevOps/public-api-data-actions-integration-module.git?ref=main"
    integration_name                = "SurveyDataActionsInteg"
    integration_creds_client_id     = var.client_id
    integration_creds_client_secret = var.client_secret
}

resource "genesyscloud_integration_action" "action" {
    name = "SendAgentlessOutboundMessage"
    category       = module.integration.integration_name
    integration_id = module.integration.integration_id
    secure         = false
    contract_input = jsonencode({
        "type" = "object",
        "required" = [
          "fromAddress",
          "toAddress",
          "textBody"
        ],
        "properties" = {
          "fromAddress" = {
            "description" = "The messaging address of the sender of the message. For an SMS messenger type, this must be a currently provisioned sms phone number.",
            "type" = "string"
          },
          "toAddress" = {
            "description" = "The messaging address of the recipient of the message. For an SMS messenger type, the phone number address must be in E.164 format. E.g. +13175555555 or +34234234234.",
            "type" = "string"
          },
          "toAddressMessengerType" = {
            "description" = "The recipient messaging address messenger type. Valid values: sms, facebook, twitter, line, whatsapp. Default value is sms.",
            "default" = "sms",
            "type" = "string"
          },
          "textBody" = {
            "description" = "The text of the message to send.",
            "type" = "string"
          }
        },
        "additionalProperties" = true
    })
    contract_output = jsonencode({
        "type" = "object",
        "properties" = {
          "id" = {
            "description" = "The globally unique identifier for the object.",
            "type" = "string"
          }
        },
        "additionalProperties" = true
    })
    config_request {
        request_url_template = "/api/v2/conversations/messages/agentless"
        request_type         = "POST"
        request_template = "{\n  \"fromAddress\": \"$${input.fromAddress}\",\n  \"toAddress\": \"$${input.toAddress}\",\n  \"toAddressMessengerType\": \"$${input.toAddressMessengerType}\",\n  \"textBody\": \"$${input.textBody}\"\n}"
    }
    config_response {
        translation_map = {
            id =  "$$.id"
        }
        translation_map_defaults = {
            id = "\"\""
        }
        success_template = "{\"id\": $${id}}"
    }
}