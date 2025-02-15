---
title: Send a web-based survey via SMS
author: dave.gussin
indextype: blueprint
icon: blueprint
image: images/processoverview.png
category: 7
summary: This Genesys Cloud Developer Blueprint explains how to send customers an SMS message that contains an invitation to complete a web-based survey about a recent interaction. It also illustrates how to configure the process with CX as Code and Archy components.
---
:::{"alert":"primary","title":"About Genesys Cloud Blueprints","autoCollapse":false} 
Genesys Cloud blueprints were built to help you jump-start building an application or integrating with a third-party partner. 
Blueprints are meant to outline how to build and deploy your solutions, not a production-ready turn-key solution.
 
For more details on Genesys Cloud blueprint support and practices 
please see our Genesys Cloud blueprint [FAQ](https://developer.genesys.cloud/blueprints/faq) sheet.
:::

This Genesys Cloud Developer Blueprint explains how to send customers an SMS message that contains an invitation to complete a web-based survey about a recent interaction. It also illustrates how to configure the process with CX as Code and Archy components.

:::primary
**Note**: The customer interaction can occur on any channel.
:::

![Process overview](images/processoverview.png "Process overview")

This solution uses a web survey, a web survey policy, and a survey invite flow, as shown in the following diagram.

![Web-based survey via SMS flowchart](images/flowchart.png "Web-based survey via SMS flowchart")

* When a customer interaction completes, a web survey policy determines if that interaction should be surveyed.
* When you define the web survey policy, you can specify any combination of matching criteria. You can also include the selection of a survey invite flow.
* The survey invite flow completes the following steps:

    1. Validates that the corresponding external contact record exists and whether it contains a cell phone number and (optionally) a first name
    2. Confirms that the external contact has not opted-out of receiving surveys
    3. Sends the customer an SMS message with a message that invites the customer to click a link to complete the survey
    4. Executes a data action that uses a fake email address to activate the survey

## Solution components

* **Genesys Cloud CX** - A suite of Genesys cloud services for enterprise-grade communications, collaboration, and contact center management. In this solution, you configure policies, survey forms, SMS numbers, email addresses, DID numbers, call routes, flows, queues, and data actions in Genesys Cloud.
* **Archy** - A Genesys Cloud command-line tool for building and managing Architect flows.
* **CX as Code** - A Genesys Cloud Terraform provider that provides a command line interface for declaring core Genesys Cloud objects.

## Prerequisites

### Specialized knowledge

* Administrator-level knowledge of Genesys Cloud
* Experience designing Architect flows
* An understanding of how to use data actions
* Experience creating web surveys
* Experience using Terraform or Terraform Cloud
* Experience using Archy

### Genesys Cloud account

* A Genesys Cloud 3 license. For more information, see [Genesys Cloud Pricing](https://www.genesys.com/pricing "Opens the pricing article").
* The Master Admin role in Genesys Cloud. For more information, see [Roles and permissions overview](https://help.mypurecloud.com/?p=24360 "Opens the Roles and permissions overview article") in the Genesys Cloud Resource Center.
* Genesys Cloud OAuth client. The data action that sends the agentless outbound SMS message requires an integration that is authenticated via an OAuth client.
* Genesys Cloud Architect flow. This flow routes customer interactions to a queue that an agent handles. This flow can be an existing one, or a flow that you create specifically for this solution.
* Genesys Cloud queue. The queue that the Architect flow uses for customer interactions. The media retention policy triggers the survey invite flow when customer interactions that are routed to this queue are closed.
* Genesys Cloud call route. A route that assigns an inbound number to the Architect flow.

### Development tools running in your local environment

* Terraform (the latest binary). For more information, see [Download Terraform](https://www.terraform.io/downloads.html "Opens the Download Terraform page") in the Terraform website.
* Archy. For more information, see [Archy Installation](https://developer.genesys.cloud/devapps/archy/install "Opens the Archy Installation page")

## Preliminary considerations

Before you send web surveys by SMS, review the following sections.

### Incremental SMS messaging costs

Because web surveys are delivered by SMS, you will incur an incremental usage cost for each message that is sent to customers. For more information, see [About SMS messaging](https://help.mypurecloud.com/?p=241289 "Goes to the About SMS messaging article") in the Genesys Cloud Resource Center.

### Survey invitation messages

Canned responses cannot be used to provide survey invitation templates because the Get Response action in an email flow returns a message in HTML format, and this format is incompatible with SMS messages. As a result, the survey invitation message must either be statically set in the survey invite flow, or it must come from another source like a data table or an external system via a data action.

### Survey reminders

Because surveys are delivered by SMS, you will not be able to leverage the web survey reminder feature. This feature requires the survey to be delivered by email.

### SMS rate limits

There are fixed rate limits for outbound SMS messages. For more information, see [Messaging](https://developer.genesys.cloud/organization/organization/limits#messaging "Goes to the Messaging page") in the Genesys Cloud Developer Center.

## Implementation steps

###	Create an SMS number for delivering surveys

Create an SMS number that delivers surveys to your customers. You may use an SMS number that you have already purchased. The SMS number can be a long code or a short code. To procure an SMS number, navigate to the **Message** > **SMS Number Inventory** workspace. For more information, see [About SMS messaging](https://help.mypurecloud.com/?p=241289 "Goes to the About SMS messaging article in the Genesys Cloud Resource Center").

Make a note of the SMS number for use later in this solution.

### Create an email domain

If you already configured an email domain in Genesys Cloud, skip the following steps. Make a note of your existing domain name and any existing email addresses for use later in this solution.

To configure a new email domain in Genesys Cloud:
1. In Genesys Cloud, navigate to **Admin** > **Contact Center** > **Email**.
2. Click **Add Domain**.
3. From the **Domain Type** list, select Genesys Cloud
4. In the **Domain Name** box, type the name of your domain. For example, type your company name, your Genesys Cloud organization name, and so on.
5. Click **Save.**

:::primary
**Note:** It is not necessary to create an email address for this domain.
:::

### Add the person who will test this solution as an external contact in Genesys Cloud

If the tester is already an external contact in Genesys Cloud, skip this section.

:::primary
**Note:** Make sure that the **Opt out of surveys** option is not selected in the tester's external contact record.
:::

1.  In Genesys Cloud, from the **Directory** menu, click **External Contacts**.
2.  Click **Add** and then click **Contact**
4.  Enter the tester's name and continue.
5.  Enter the tester's contact information. Be sure to do the following:
    * Specify a valid cell phone number.
    * Do not select the **Opt out of surveys** option.
6. Click **Save**.

### Define the environment variables

The following environment variables hold the OAuth credential grant that is used by CX as Code to provision the Genesys Cloud objects.

* `GENESYSCLOUD_OAUTHCLIENT_ID` - This variable is the Genesys Cloud client credential grant Id that CX as Code executes against. Mark this environment variable as sensitive.
* `GENESYSCLOUD_OAUTHCLIENT_SECRET` - This variable is the Genesys Cloud client credential secret that CX as Code executes against. Mark this environment variable as sensitive.
* `GENESYSCLOUD_REGION` - This variable is the Genesys Cloud region in which your organization is located.
* `GENESYSCLOUD_ARCHY_LOCATION` - This variable is the region domain for your organization (for example, mypurecloud.com). For more information, see [Overview](/platform/api/ "Goes to the Overview page").

### Clone the GitHub repository

Clone the [survey-sms-delivery-blueprint](https://github.com/GenesysCloudBlueprints/architect-flow-public-api-blueprint "Opens the project repository on GitHub") repository to your local machine.

### Configure the Terraform module

1. Update `terraform/terraform.tfvars` with the same client credentials that you use for the environment variables.

  ```
  client_id = "<your-client-id>"
  client_secret = "<your-client-secret>"
  ```

2. Update the queue name in `terraform/modules/media-retention-policies/main.tf` to match the queue that you will use to test this solution.

  ```hcl
  data "genesyscloud_routing_queue" "queue" {
      name = "<your-queue-name>"
  }
  ```

3. Update the email domain in `terraform/modules/media-retention-policies/main.tf`.

  ```hcl
  resource "genesyscloud_recording_media_retention_policy" "sendsurvey_policy" {
      .
      .
      .
      media_policies {
          call_policy {
              actions {
                  .
                  .
                  .
                  assign_surveys {
                      sending_domain = "<your-email-domain>"
  .
  .
  .
  ```

4. Update the customer greeting of the survey invite in `terraform/SendSurvey_v1-0.yaml`.

  ```yaml
  .
  .
  .
  - updateData:
      name: Create manual survey message
      statements:
        - string:
            variable: State.surveyMessage
            value:
              exp: "Append(\"<your-customer-greeting>\")"
  .
  .
  .
  ```

5. If you change the integration name or the data action name in `terraform/modules/data-actions/main.tf`, update them in the `terraform/SendSurvey_v1-0.yaml` file as well.

  `terraform/modules/data-actions/main.tf`
  ```hcl
  module "integration" {
      source = "git::https://github.com/GenesysCloudDevOps/public-api-data-actions-integration-module.git?ref=main"
      integration_name                = "<your-integration-name>"
  .
  .
  .
  ```

  ```hcl
  resource "genesyscloud_integration_action" "action" {
      name = "<your-data-action-name>"
  .
  .
  .
  ```

  `terraform/SendSurvey_v1-0.yaml`
  ```yaml
  .
  .
  .
  - callData:
      name: Call Data Action
      category:
        <your-integration-name>:
          dataAction:
            <your-data-action-name>:
  .
  .
  .

  ```

### Deploy the Architect flow and Genesys Cloud objects

From the directory containing `main.tf` and `SendSurvey_v1-0.yaml`, run:

```console
$ terraform init
$ terraform apply --auto-approve
```

## Test your flow

Have the tester dial the DID phone number assigned to the Architect flow outlined in the [Genesys Cloud configuration](#create-an-sms-number-for-delivering-surveys "Goes to the Create an SMS Number for Delivering Surveys") section. After the call is transfered to an agent and the call is ended, the tester should receive an SMS message with the survey invitation.

:::primary
**Tip:** As the tester, it may be convenient to act as both the customer and agent in this scenario.
:::

## Additional resources
* [terraform.io home page](https://terraform.io "Opens the Terraform home page")
* [Genesys Cloud Provider page](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs "Opens the Genesys Cloud Provider page") in the Terraform Registry site
* [CX as Code](https://developer.genesys.cloud/devapps/cx-as-code/ "Opens the CX as Code page")
* [Welcome to Archy](https://developer.genesys.cloud/devapps/archy/ "Opens the Welcome to Archy page")
* ["Deploy a simple IVR using Terraform, CX as Code, and Archy blueprint"](https://developer.genesys.cloud/blueprints/simple-ivr-deploy-with-cx-as-code-blueprint/ "Opens the Deploy a simple IVR using Terraform, CX as Code, and Archy blueprint").
* [Architect overview](https://help.mypurecloud.com/articles/architect-overview/ "Opens the Architect overview article") in the Genesys Cloud Resource Center
* [About web surveys](https://help.mypurecloud.com/?p=175240 "Opens the About web surveys article") in the Genesys Cloud Resource Center
* [Manage ACD email routing](https://help.mypurecloud.com/?p=64853 "Opens the Manage ACD email routing article") in the Genesys Cloud Resource Center
* [About the Genesys Cloud data actions integration](https://help.mypurecloud.com/?p=144553 "Opens the About the Genesys Cloud data actions integration article") in the Genesys Cloud Resource Center
* [survey-sms-delivery-blueprint](https://github.com/GenesysCloudBlueprints/survey-sms-delivery-blueprint "Opens the project repository on GitHub") repository on GitHub
