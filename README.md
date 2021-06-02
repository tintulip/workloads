# Preproduction
This will set up the infrastructure for the preproduction account


## The repository structure

- `module-template`: contains grouped resources that are frequently used
- `components`: `module-template` modules these modules and
- `environments`: specifies the different environment that will use `components`

## Sandbox commands

needs a `tintulip-preproduction-admin` role to be set up with `aws configure sso`

```bash
AWS_REGION=eu-west-2 AWS_PROFILE=tintulip-preproduction-admin ENV=preproduction make plan
AWS_REGION=eu-west-2 AWS_PROFILE=tintulip-preproduction-admin ENV=preproduction make apply
```