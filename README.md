 # Azure Arc Validation Program 

Azure Arc can be deployed on any CNCF certified K8s clusters. For partner solutions participating in the “Arc Validation Program”, we ensure testing, quality, support and consistency across hybrid clusters. 

To achieve Arc feature consistency and quality on validated partner platforms, we've built a conformance test framework to test and validate the Arc functionality.

## Conformance Testing Integration

It is recommended that our partners integrate the conformance tests into their CI/CD pipelines to run them at the required cadence.

The conformance tests need to be run every time there's an update (major or minor) to the partner offering or to the Azure Arc components.
These components include*:
- **Arc for K8s Platform**: The core Arc for K8s platform with functionalities such as onboarding a cluster to Arc, GitOps etc.
- **Arc enabled Data Services**: Provides fully managed Azure PaaS offerings for SQLMI and PostgreSQL on your clusters on-prem or on other clouds.

*These components may grow in the future as the Azure Arc portfolio widens.

### Testing Strategy

The testing strategy can be broken down into two parts:
- **Update to partner offering**: The new version of the partner offering is tested against N, N-1 and N-2 minor versions of Arc for K8s and the latest version of Arc enabled Data Services.
- **Update to Azure Arc components**: The new version of the Azure Arc component is tested against N, N-1 and N-2 minor versions of the partner offering.

By default the test suite will install the latest versions of Arc for K8s and Arc enabled Data Services.

| Arc for K8s Minor Release | Version |
| :---: | :----: |
| N | 1.3.8 |
| N-1 | 1.2.0 |
| N-2 | 1.1.0 |

### Partner Tasks

1. Partners will run the conformance tests according to the above strategy and produce successful results as outlined in the Validation Agreement.
2. Partners will be provided access to a storage account on Azure to upload the test results. Partners may be contacted to resolve test failures if required. 
3. Partners will create/maintain the test lab for their respective offering.

### Microsoft Tasks

Microsoft will provide the testing tools and processes for partners to run the tests on their environments.
1. Microsoft will update partners on the availability of a new version of an Azure Arc component as outlined in the Validation Agreement.
2. Partners will be provided with the sonobuoy based test suite comprising of plugins for the Arc for K8s as well as Arc enabled Data Services. This test suite will be updated as the Azure Arc components evolve.
3. Storage accounts for each partner will also be provided. Partners will be given credentials (service principals, storage account SAS token) to publish the test results into these accounts.

### Failure to Address Issues in Conformance Testing
If the test failures are due to issues on the partner's side:
- If it's a new version of the partner's offering, the public documentation will not be updated to add this new version in the validated partners grid unless the issue is fixed.
- If it's a new version of Azure Arc, the public documentation will be updated to call out this limitation that the new version of Azure Arc is not supported on the failed versions of the partner offering.

# Running the Test Suite

Please refer to [this doc](testsuite/running-tests.md) for running the test suite.