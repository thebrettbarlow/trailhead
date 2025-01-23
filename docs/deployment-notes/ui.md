# Deployment Notes related to UI Elements

Contains deployment notes related to UI elements.

---

## Custom Applications

When retrieving `CustomApplication` metadata, remember to also retrieve the
`Flexipage` listed in `utilityBar`. It is automatically created with the
following naming convention: `<applicationName>_UtilityBar`.

Forgetting the Utility Bar will result in an error like this:

> utilityBar - no FlexiPage named Energy_Consultations_UtilityBar found
