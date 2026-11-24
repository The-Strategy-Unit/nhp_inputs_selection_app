## Instructions

**Please note**: by accessing this model you are acknowledging that you are aware of the implications of setting the model parameters, and have completed any relevant training.
If this is not the case, please contact your Model Relationship Manager, or contact [the Strategy Unit Data Science team](mailto:mlcsu.su.datascience@nhs.net) before proceeding.

To begin developing a scenario for the OpenPlan Hospital Demand Model, you must:

1. Be granted a Posit Connect account and be added to the appropriate provider group.
You cannot run the model otherwise. After completing the relevant training, contact [the Strategy Unit Data Science team](mailto:mlcsu.su.datascience@nhs.net) or (preferably) your Model Relationship Manager (if you have one) to set this up.
2. Select a provider, baseline year and [model (horizon) year](https://connect.strategyunitwm.nhs.uk/nhp/project_information/user_guide/FAQ.html#which-year-should-be-selected-as-the-horizon-year) in the 'Select Provider and Baseline' box.
You [must request and review your baseline data](mailto:mlcsu.su.datascience@nhs.net?subject=OpenPlan%20request%3A%20detailed%20baseline%20data&body=I%20am%20requesting%20the%20detailed%20baseline%20data%20for%20%5Bscheme%20name%5D%20for%20financial%20year%20%5BYYYY%2FYY%5D%2C%20as%20instructed%20in%20the%20OpenPlan%20Hospital%20Demand%20Model%20inputs%20app.) for the chosen year before using the model.
3. Choose to create a new scenario or edit an existing one in the 'Scenario' box.
You must [provide a sensible name](https://connect.strategyunitwm.nhs.uk/nhp/project_information/user_guide/naming_scenarios.html) that can be used to identify your scenario uniquely.
4. Click the green start button. The button will not appear until you have provided all the required inputs.

Pay attention to any messages shown in the selection boxes, which give further information or warnings.

Note that the interactive map will update when you choose a provider and its peers will be shown.
Click points on the map to reveal the name of the provider.
See the collapsed 'peers' box underneath the map for the full list of peers.

## Evidence Map

Much evidence exists in published literature of the efficacy of various methods to reduce or avoid acute hospital demand.
Although difficult to summarise, we have mapped this evidence in [an interactive app](https://connect.strategyunitwm.nhs.uk/nhp_evidence_map/) to provide an overview, categorised by setting, evidence type, outcomes and effect.
This map is provided to enable exploration of the current evidence landscape, identify gaps in knowledge, and allow searching of evidence by a range of parameters.

## Advanced Options

By default, advanced options are hidden in a collapsed box.
There are two options that can be adjusted here:

1. The random seed used for the model run. This defaults to a random value each time, but can be set to a specific value to repeat a prior model run.
2. The number of iterations to use within the Monte-Carlo simulation, which defaults to 256 runs, but can be set to 512 or 1024 runs.
