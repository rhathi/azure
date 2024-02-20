# Create resource group
az group create --location "Southeast Asia" --name rg-mcade

# Create data factory extension
az extension add --upgrade -n datafactory

# Create data factory instance
az datafactory create --location "Southeast Asia" --name "rhathi-adf1" --resource-group rg-mcade

# Create linked service to connect external endpoint (external source)
az datafactory linked-service create --factory-name rhathi-adf1 --resource-group rg-mcade --name PandemicService --properties "@pandemic-service.json"

# Create dataset for the external endpoint (external source)
az datafactory dataset create --factory-name "rhathi-adf1" --resource-group rg-mcade --name pandemicdataset --properties '@pandemic-dataset.json'

# Create storage account (blob storage)
az storage account create --name rhathitestblobstorage --resource-group rg-mcade --location "Southeast Asia" --sku Standard_LRS --kind StorageV2 --allow-blob-public-access false

# Create container (bucket)
az storage container create --account-name rhathitestblobstorage --name data1

# Create key vault (to store passwords and secrets)
az keyvault create --name "rhathi-dev-key" --resource-group "rg-mcade" --location "Southeast Asia" --enable-purge-protection

# Get the service principal id of ADF
ADF_SID=$(az datafactory show --name rhathi-adf1  --resource-group rg-mcade --query identity.principalId --output tsv)

# Assign permission to the above SID to get and list the keys in key vault
az keyvault set-policy --name "rhathi-dev-key" --object-id $ADF_SID --secret-permissions get list

# Create key vault linked service
az datafactory linked-service create --factory-name rhathi-adf1 --resource-group rg-mcade --name akv-service --properties "@akv-service.json"

# Retrieve the blob storage account key, resource id, connection string
key=$(az storage account keys list --resource-group rg-mcade --account-name rhathitestblobstorage --query '[0].value' -o tsv)
id=$(az storage account list -g rg-mcade --query '[0].id' -o tsv)
cs=$(az storage account show-connection-string --key key1 -n rhathitestblobstorage -o tsv)

# Store the blob storage secret key in Azure Key Vault
az keyvault secret set --name blob-storage-key1 --vault-name rhathi-dev-key --value $cs

# Create blob storage linked service
az datafactory linked-service create --factory-name rhathi-adf1 --resource-group rg-mcade --name blob-storage-service --properties "@blob-storage-service.json"

# Create dataset for sink (blob storage)
az datafactory dataset create --factory-name "rhathi-adf1" --resource-group rg-mcade --name pandemicdata --properties '@pandemic-data.json'

# Create a pipeline that will run copy activity to ingest data from external source to blob storage using API
az datafactory pipeline create --factory-name rhathi-adf1 -g rg-mcade -n api-pipeline --pipeline pipeline.json

# Triggers or executes the pipeline (monitor the progress from UI)
az datafactory pipeline create-run --factory-name rhathi-adf1 -g rg-mcade -n api-pipeline
