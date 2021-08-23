# Contribution Guidelines

This project welcomes contributions and suggestions. Most contributions require you to
agree to a Contributor License Agreement (CLA) declaring that you have the right to,
and actually do, grant us the rights to use your contribution. For details, visit
[https://cla.microsoft.com](https://cla.microsoft.com).

When you submit a pull request, a CLA-bot will automatically determine whether you need
to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the
instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

Contributions come in many forms: submitting issues, writing code, and participating in discussions or questions.

## Use of Third-party code

Third-party code must include the associated license in the [`NOTICE`](NOTICE) file.

## Contribution Process

### Select an Issue

Team members select issues to develop. More than one member can work on a single issue, and pair programming and other collaboration is encouraged. Generally, issues that have higher priority should be done before lower priority issues, but any issue may be selected from the backlog by any team member.

### Create a Branch

Issues that require code or documentation changes should be developed on a branch. These are guidelines for branching (not strict requirements):

- The naming convention for branches is `<team member name or ID>/<one or two word description>`.
- Every day, branches should be reverse integrated with main and updated from work in progress on the development machine.
- Branches can be in a broken state.

### Develop

Keep short dev/test/commit cycles within a branch, and create many commits per day. Keep the development branch in sync with main to avoid difficult merges. Stay in contact with teammates about what is changing so that merges do not conflict.

### Submit a PR

Multiple PRs can be created for an issue, but there is usually a single pull request per issue. Optionally ask specific teammates for a review. Carefully follow the checklist in the PR template. Ensure that at least one GitHub issue is associated with the PR and assigned to the current release. When the PR is completed/closed, make sure the GitHub issue is also closed.

A draft PR can be used to request feedback from the team.

### Review Other PRs

When PRs are requested, review each change and run a full test deployment, specifically focused on the areas that have changed. Provide comments and feedback directly related to the PR.

### Ensure Quality

The main branch is always production quality. The PR reviewer is responsible for ensuring that code merged to main meets our quality standards.

## Our Thanks

**Thank You!** - Your contributions to open source, large or small, make projects like this possible. Thank you for taking the time to contribute.
