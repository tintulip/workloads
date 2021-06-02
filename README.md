# Preproduction
This will set up the infrastructure for the preproduction account


## The repository structure
This repository has the following directories :

- Module-template
- Components
- Environments

The Module-template directory contains grouped resources that are frequently used, components directory uses these modules and the environemnts directory specifies the different environment that will use these resources.


## Sandbox commands

```bash
AWS_REGION=eu-west-2 AWS_PROFILE=tintulip-sandbox-admin ENV=sandbox make plan
AWS_REGION=eu-west-2 AWS_PROFILE=tintulip-sandbox-admin ENV=sandbox make apply
```