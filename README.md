# quickstart-ibaset-solumina
## Solumina on the AWS Cloud

**Solumina** is a Manufacturing Execution System (MES) software suite that manages work and quality processes for the manufacturing maintenance, repair, and overhaul of engineered products.

This Quick Start reference deployment guide provides step-by-step instructions for deploying iBASEt’s Solumina MES on the AWS Cloud. 

![Quick Start architecture for Solumina MES](https://d0.awsstatic.com/partner-network/QuickStart/ibaset-solumina-architecture.png)

The Quick Start supports two standardized architectures and provides automatic deployment options for Solumina:
- Standalone architecture. Installs Solumina on an Amazon EC2 instances running CentOS 7 x86_64 HVM. 
This architecture is deployed into a new or existing VPC.
- Cluster architecture. Installs Solumina on at least three Amazon EC2  instances running CentOS 7 x86_64 HVM.
 This option builds a new AWS environment consisting of the VPC, subnets, NAT gateways, 
 security groups, bastion host (on an Amazon EC2 t2.micro instance), and other infrastructure components, 
 and then deploys Solumina into a new or existing VPC. 
This Quick Start provides the following deployment options: 
- Deploy Solumina on CentOS into a new VPC (cluster architecture) 
- Deploy Solumina on CentOS into an existing VPC (cluster architecture)

For architectural details, best practices, step-by-step instructions, and customization options, see the 
[deployment guide](https://fwd.aws/v3QxK).

To post feedback, submit feature ideas, or report bugs, use the **Issues** section of this GitHub repo.
If you'd like to submit code for this Quick Start, please review the [AWS Quick Start Contributor's Kit](https://aws-quickstart.github.io/).
