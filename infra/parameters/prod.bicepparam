using '../main.bicep'

/* This parameter file configures the deployment for the production environment. */

param environmentName = 'prod'
param location = 'useast'
param repositoryName = 'tv-azurevirtualdesktop'
param division = 'Information Technology'
param product = 'AVD'
param workloadName = 'prod-workload'
