using 'main.bicep'

param environment = 'poc'
param fslogixShareName = 'profiles'

// Admin/operator groups that can manage FSLogix share ACLs
param avdAdminGroupObjectIds = [
  '53422f94-8888-496a-b3b8-18e062da591c'
]

// AVD user groups that need standard FSLogix profile share access
param avdUserGroupObjectIds = [
  '1cc07c58-29fd-4b99-98df-b36e3cd9a7ae'
  'aa09d144-a544-4cc9-b0bc-ff053061445c'
  'ebdf4719-7e5e-4b65-89a5-2a7d24627f75'
]
