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

module "flows" {
    source = "../flows"
    client_id = var.client_id
    client_secret = var.client_secret
}

data "genesyscloud_flow" "sendsurvey_flow" {
  depends_on = [
    module.flows,
  ]
  name = "SendSurvey"
}

data "genesyscloud_routing_queue" "queue" {
    name = "Transcription Queue"
}

resource "genesyscloud_quality_forms_survey" "survey_form" {
  name      = "Survey Form"
  published = true
  disabled  = false
  language  = "en-US"
  header    = ""
  footer    = ""
  question_groups {
    name       = "Test Question Group 1"
    na_enabled = false
    questions {
      text                    = "Would you recommend our services?"
      help_text               = ""
      type                    = "npsQuestion"
      na_enabled              = false
      max_response_characters = 100
      explanation_prompt      = "explanation-prompt"
    }
    questions {
      text                    = "Are you satisifed with your experience?"
      help_text               = "Help text here"
      type                    = "freeTextQuestion"
      na_enabled              = true
      max_response_characters = 100
      explanation_prompt      = ""
    }
    questions {
      text       = "Would you recommend our services?"
      help_text  = ""
      type       = "multipleChoiceQuestion"
      na_enabled = false
      answer_options {
        text  = "Yes"
        value = 1
      }
      answer_options {
        text  = "No"
        value = 0
      }
      max_response_characters = 0
    }
  }
  question_groups {
    name       = "Test Question Group 2"
    na_enabled = false
    questions {
      text       = "Did the agent offer to sell product?"
      help_text  = ""
      type       = "multipleChoiceQuestion"
      na_enabled = false
      visibility_condition {
        combining_operation = "AND"
        predicates          = ["/form/questionGroup/0/question/2/answer/1"]
      }
      answer_options {
        text  = "Yes"
        value = 1
      }
      answer_options {
        text  = "No"
        value = 0
      }
      max_response_characters = 0
      explanation_prompt      = ""
    }
    visibility_condition {
      combining_operation = "AND"
      predicates          = ["/form/questionGroup/0/question/2/answer/1"]
    }
  }
}

resource "genesyscloud_recording_media_retention_policy" "sendsurvey_policy" {
    depends_on = [
        module.flows,
    ]
    name        = "Survey Policy"
    order       = 1
    description = "Send survey via sms"
    enabled     = true
    media_policies {
        call_policy {
            actions {
                retain_recording = true
                delete_recording = false
                always_delete    = false
                assign_surveys {
                    sending_domain = "surveys.mypurecloud.com"
                    survey_form_name = genesyscloud_quality_forms_survey.survey_form.name 
                    flow_id = data.genesyscloud_flow.sendsurvey_flow.id
                }
            }
            conditions {
                for_queue_ids = [data.genesyscloud_routing_queue.queue.id]
            }
        }
    }
}