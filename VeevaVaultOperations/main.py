import datetime
from pickle import NONE
import requests
import pyodbc

server = 'odsproduction.database.windows.net'
database = 'ProdMonitoring' # DB Servie Name
username = 'odsjobsuser' # DB User Name
password = 'ProdMonJobs$$034789!!'   # DB Password
#driver= '{ODBC Driver 11 for SQL Server}'  
#driver= '{SQL Server Native Client 11.0}'
driver= '{SQL Server}'

conn = pyodbc.connect('DRIVER='+driver+';SERVER='+server+';PORT=1433;DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = conn.cursor()

sql="Select * from  Vaultcustomer Where Isactive = 1 Order By Id"

cursor.execute(sql)
result=cursor.fetchall()

sessionId = ''
tempData = []
customerId = ''
vaultId = ''
VaultCustomerAPIConfig = 'VaultCustomerAPIConfig'
VaultCustomer = 'VaultCustomer'
vaultMaster = 'VaultMaster'


def Get_APIResponse(baseUrl, respDetails):
    url = respDetails.get("next_page")
    if url is not None:
        resp = requests.request('get', baseUrl + url, headers=headers,timeout=30)
        resp = resp.json()
        if resp.get("responseStatus") == 'SUCCESS' and resp.get("data") is not None:
            tempData.extend(resp.get("data"))
    
        if resp.get("responseStatus") == 'SUCCESS' and resp.get("jobs") is not None:
            tempData.extend(resp.get("jobs"))

        Get_APIResponse(baseUrl, resp.get("responseDetails"))

    return tempData

def Get_AuthToken(apiConfig, parameters):
    r=requests.post(getattr(apiConfig, 'URL'),params=parameters)
    sessionId = r.json().get("sessionId")
    return sessionId

def Save_LastSyncedOn(tableName, entityName):
    currentDateTime = datetime.datetime.now()
    f = '%Y-%m-%d %H:%M:%S'
    currentDateTime = currentDateTime.strftime(f)
    sql = "Update " + tableName + " Set LastSyncedOn = '" + "{}".format(currentDateTime) + "' Where VaultId=" + vaultId  + " and type='" + entityName + "'"
    
    if tableName == 'VaultMaster':
        sql = "Update " + tableName + " Set LastSyncedOn = '" + "{}".format(currentDateTime) + "' Where Id=" + vaultId 
    cursor.execute(sql)
    cursor.commit()

def Save_Error(tableName, error, entityName):
    sql = "Update " + tableName + " Set Error = '" + error + "' Where Id=" + vaultId

    if tableName == 'VaultCustomerAPIConfig':
        sql = sql + " and type=" + entityName

    cursor.execute(sql)
    cursor.commit()

def Get_Products(apiConfig):
    response = requests.request('get', getattr(apiConfig, 'URL'), headers=headers, timeout=30)
    response = response.json()

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from VaultProducts where customerid=" + customerId + " And vaultId=" + vaultId)   
        cursor.commit() 

        data = response.get("data")

        for item in data:
            sql = "Insert into VaultProducts Values('" + item['id'] + "','" + item['name__v'].replace("'","''") + "',"  + customerId + "," + vaultId + ")" 
            cursor.execute(sql)
        cursor.commit()
        Save_LastSyncedOn(VaultCustomerAPIConfig, 'Product')

def Get_Countries(apiConfig):
    response = requests.request('get', getattr(apiConfig, 'URL'), headers=headers, timeout=30)
    response = response.json()

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from VaultCountries where customerid=" + customerId + " And vaultId=" + vaultId)     
        cursor.commit() 

        data = response.get("data")

        for item in data:           
            sql = "Insert into VaultCountries Values('" + item['id'] + "','" + item['name__v'].replace("'","''") + "',"  + customerId + "," + vaultId + ")"
            cursor.execute(sql)
        cursor.commit()
        Save_LastSyncedOn(VaultCustomerAPIConfig, 'Country')

def Get_Documents(apiConfig):
    query = ''
    if getattr(apiConfig, 'Query') is not None:
        query = getattr(apiConfig, 'Query')

    response = requests.request('get', getattr(apiConfig, 'URL') + query, headers=headers, timeout=30)
    response = response.json()

    data = []
    global tempData 
    tempData = []

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from Vault_Documents where customerid=" + customerId + " And vaultId=" + vaultId)   
        cursor.commit()   

        data = response.get("data")
        moreData = Get_APIResponse(getattr(apiConfig, 'BaseURL'), response.get("responseDetails"))
        if len(moreData) is not 0:
            data.extend(moreData)

        for item in data:
            if item['country__v'] is not None:
                countries = ", ".join(str(item) for item in item['country__v'])
            else:
                countries = "null"

            if item['product__v'] is not None:
                products = ", ".join(str(item) for item in item['product__v'])
            else:
                products = "null"

            # countries = item['country__v'] if item['country__v'] is not None else "null"
            # products = item['product__v'] if item['product__v'] is not None else "null"
            arrFieldTeams = item.get('field_team__c') if item.get('field_team__c') is not None else "null"
            #clmContent =  '1' if item['clm_content__v'] == 'True' else '0'

            if arrFieldTeams is not "null":
                fieldTeams = ", ".join(str(item) for item in arrFieldTeams)
                fieldTeams = "'" + fieldTeams + "'"
            else:
                fieldTeams = "null"

            sql = "Insert into Vault_Documents Values(" + "{}".format(item['id']) + ",'" + item['document_number__v'] + "','"  + item['name__v'].replace("'","''") + "',"  + "{}".format(item['major_version_number__v']) + "," + "{}".format(item['minor_version_number__v']) + ",'" + item['status__v'] + "','" + item['type__v'] + "',null," + customerId + ",'" + countries + "','" + products + "'," + vaultId + "," + fieldTeams + "," + "{}".format(int(item['clm_content__v'])) + ")" 
            cursor.execute(sql)
        cursor.commit()
        Save_LastSyncedOn(VaultCustomerAPIConfig, 'Documents')

def Get_Users(apiConfig):
    query = ''
    if getattr(apiConfig, 'Query') is not None:
        query = getattr(apiConfig, 'Query')

    response = requests.request('get', getattr(apiConfig, 'URL') + query, headers=headers, timeout=30)
    response = response.json()

    data = []
    global tempData 
    tempData = []

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from Vault_Users where customerid=" + customerId + " And vaultId=" + vaultId)     
        cursor.commit()

        data = response.get("data")
        moreData = Get_APIResponse(getattr(apiConfig, 'BaseURL'), response.get("responseDetails"))
        if len(moreData) is not 0:
            data.extend(moreData)

        for item in data:
            userName = "'" + item['user_name__v'] + "'" if item['user_name__v'] is not None else "null"
            firstName = "'" + item['user_first_name__v'] + "'" if item['user_first_name__v'] is not None else "null"
            lastName = "'" + item['user_last_name__v'] + "'" if item['user_last_name__v'] is not None else "null"
            licenseType = "'" + item['license_type__v'] + "'" if item['license_type__v'] is not None else "null"
            securityProfile = "'" + item['security_profile__v'] + "'" if item['security_profile__v'] is not None else "null"
            lastLogin = "'" + item['last_login__v'] + "'" if item['last_login__v'] is not None else "null"
            sql = "Insert into Vault_Users Values(" + "{}".format(item['id']) + "," + userName + ","  + firstName + ","  + lastName + ",'" + "{}".format(item['active__v']) + "'," + licenseType + "," + securityProfile + "," + lastLogin + "," + customerId + "," + vaultId + ",null,null,null,null)"
            cursor.execute(sql)
        cursor.commit()

        Save_LastSyncedOn(VaultCustomerAPIConfig, 'Users')

def Get_Binders(apiConfig):
    query = ''
    if getattr(apiConfig, 'Query') is not None:
        query = getattr(apiConfig, 'Query')

    response = requests.request('get', getattr(apiConfig, 'URL') + query, headers=headers, timeout=30)
    response = response.json()

    data = []
    global tempData 
    tempData = []

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from Vault_Binders where customerid=" + customerId + " And vaultId=" + vaultId) 
        cursor.commit()

        data = response.get("data")
        moreData = Get_APIResponse(getattr(apiConfig, 'BaseURL'), response.get("responseDetails"))
        if len(moreData) is not 0:
            data.extend(moreData)

        for item in data:
            docNum = "'" + item['document_number__v'] + "'" if item['document_number__v'] is not None else "null"
            name = "'" + item['name__v'] + "'" if item['name__v'] is not None else "null"
            majorVN = item['major_version_number__v'] if item['major_version_number__v'] is not None else "null"
            minorVN = item['minor_version_number__v'] if item['minor_version_number__v'] is not None else "null"
            status = "'" + item['status__v'] + "'" if item['status__v'] is not None else "null"
            type = "'" + item['type__v'] + "'" if item['type__v'] is not None else "null"
            arrFieldTeams = item.get('field_team__c') if item.get('field_team__c') is not None else "null"
            if arrFieldTeams is not "null":
                fieldTeams = ", ".join(str(item) for item in arrFieldTeams)
                fieldTeams = "'" + fieldTeams + "'"
            else:
                fieldTeams = "null"

            sql = "Insert into Vault_Binders Values(" + "{}".format(item['id']) + "," + docNum + ","  + name + ","  + "{}".format(majorVN) + "," + "{}".format(minorVN) + "," + status + "," + type + ","+ customerId + "," + vaultId + "," + fieldTeams + ", null)"
            cursor.execute(sql)
        cursor.commit()

        Save_LastSyncedOn(VaultCustomerAPIConfig, 'Binders')

def Get_Monitors(apiConfig):
    query = ''
    if getattr(apiConfig, 'Query') is not None:
        query = getattr(apiConfig, 'Query')

    response = requests.request('get', getattr(apiConfig, 'URL') + query, headers=headers, timeout=30)
    response = response.json()

    data = []
    global tempData 
    tempData = []

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from Vault_JobsMonitor where customerid=" + customerId + " And vaultId=" + vaultId)  
        cursor.commit()
        data = response.get("jobs")
        moreData = Get_APIResponse(getattr(apiConfig, 'BaseURL'), response.get("responseDetails"))

        if len(moreData) is not 0:
            data.extend(moreData)

        for item in data:
            title = "'" + item['title'] + "'" if item['title'] is not None else "null"
            status = "'" + item['status'] + "'" if item['status'] is not None else "null"
            createdBy = item['created_by'] if item['created_by'] is not None else "null"
            createdDate = "'" + item['created_date'] + "'" if item['created_date'] is not None else "null"
            modifiedBy = item['modified_by']  if item['modified_by'] is not None else "null"
            modifiedDate = "'" + item['modified_date'] + "'" if item['modified_date'] is not None else "null"
            runStartDate = "'" + item['run_start_date'] + "'" if item['run_start_date'] is not None else "null"
            sql = "Insert into Vault_JobsMonitor Values(" + "{}".format(item['job_id']) + "," + title + ","  + status + ","  + "{}".format(createdBy) + "," + createdDate + "," + "{}".format(modifiedBy) + "," + modifiedDate + "," + runStartDate + ","+ customerId + "," + vaultId + ",null)" 
            cursor.execute(sql)
        cursor.commit()

        Save_LastSyncedOn(VaultCustomerAPIConfig, 'Monitors')

def Get_Histories(apiConfig):
    query = ''
    if getattr(apiConfig, 'Query') is not None:
        query = getattr(apiConfig, 'Query')

    response = requests.request('get', getattr(apiConfig, 'URL') + query, headers=headers, timeout=30)
    response = response.json()

    data = []
    global tempData 
    tempData = []

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from Vault_JobsHistory where customerid=" + customerId + " And vaultId=" + vaultId) 
        cursor.commit()
        data = response.get("jobs")
        moreData = Get_APIResponse(getattr(apiConfig, 'BaseURL'), response.get("responseDetails"))

        if len(moreData) is not 0:
            data.extend(moreData)

        for item in data:
            title = "'" + item['title'] + "'" if item['title'] is not None else "null"
            status = "'" + item['status'] + "'" if item['status'] is not None else "null"
            createdBy = item['created_by'] if item['created_by'] is not None else "null"
            createdDate = "'" + item['created_date'] + "'" if item['created_date'] is not None else "null"
            modifiedBy = item['modified_by']  if item['modified_by'] is not None else "null"
            modifiedDate = "'" + item['modified_date'] + "'" if item['modified_date'] is not None else "null"
            runStartDate = "'" + item['run_start_date'] + "'" if item['run_start_date'] is not None else "null"


            if 'run_end_date' in item:
                runEndDate = "'" + item['run_end_date'] + "'" if item['run_end_date'] is not None else "null"
            else:
                runEndDate = "null"
            sql = "Insert into Vault_JobsHistory Values(" + "{}".format(item['job_id']) + "," + title + ","  + status + ","  + "{}".format(createdBy) + "," + createdDate + "," + "{}".format(modifiedBy) + "," + modifiedDate + "," + runStartDate + "," + runEndDate +  ","+ customerId + "," + vaultId + ",null)"
            cursor.execute(sql)
        cursor.commit()

        Save_LastSyncedOn(VaultCustomerAPIConfig, 'Histories')

def Get_LoginAuditTrail(apiConfig):            
    query = ''
    if getattr(apiConfig, 'Query') is not None:
        query = getattr(apiConfig, 'Query')

    response = requests.request('get', getattr(apiConfig, 'URL') + query, headers=headers, timeout=30)
    response = response.json()

    data = []
    global tempData 
    tempData = []

    if response.get("responseStatus") == 'SUCCESS':
        cursor.execute("delete from Vault_AuditTrail where customerid=" + customerId + " And vaultId=" + vaultId)  
        cursor.commit()
        data = response.get("data")
        moreData = Get_APIResponse(getattr(apiConfig, 'BaseURL'), response.get("responseDetails"))

        if len(moreData) is not 0:
            data.extend(moreData)

        for item in data:
            timeStamp = "'" + item['timestamp'] + "'" if item['timestamp'] is not None else "null"
            userName = "'" + item['user_name'] + "'" if item['user_name'] is not None else "null"
            sourceIP = "'" + item['source_ip'] + "'" if item['source_ip'] is not None else "null"
            type = "'" + item['type'] + "'" if item['type'] is not None else "null"
            status = "'" + item['status'] + "'" if item['status'] is not None else "null"
            browser = "'" + item['browser'] + "'" if item['browser'] is not None else "null"
            platform = "'" + item['platform'] + "'" if item['platform'] is not None else "null"
            auditTrailVaultId = "'" + item['vault_id'] + "'" if item['vault_id'] is not None else "null"
            sql = "Insert into Vault_AuditTrail Values(" + "{}".format(item['id']) + "," + timeStamp + ","  + userName + ","  + sourceIP + "," + type + "," + status + "," + browser + "," + platform + "," + auditTrailVaultId +  ","+ customerId + "," + vaultId + ",null)" 
            cursor.execute(sql)
        cursor.commit()

        Save_LastSyncedOn(VaultCustomerAPIConfig, 'LoginAuditTrail')

for customer in result:

    sql = "Select * from VaultMaster where customerId=" + "{}".format(getattr(customer, 'Id')) + " order by Id"
    cursor.execute(sql)
    vaults = cursor.fetchall()
    customerId = ''
    customerId = "{}".format(getattr(customer, 'Id'))

    for vault in vaults:

        vaultId = ''
        vaultId = "{}".format(getattr(vault, 'Id'))
        authParameters={"username":  getattr(vault, 'UserName'),"password": getattr(vault, 'PasswordKey')}  
        
        sql = "Select * from vaultcustomerAPIConfig where VaultId=" + "{}".format(getattr(vault, 'Id')) + " order by SortOrder"
        cursor.execute(sql)
        apiConfigs = cursor.fetchall()
        
        for api in apiConfigs:

            if (getattr(api, 'Type') == 'Auth'):
                sessionId = Get_AuthToken(api, authParameters)
                if sessionId is not None:
                    headers = {
                                'Content-type': 'application/json',
                                'Accept-Encoding': 'gzip',
                                'Authorization': sessionId
                            }
                else:
                    Save_Error(vaultMaster, 'Error in Authorization', '')
                    break

            elif (getattr(api, 'Type') == 'Product'):
                Get_Products(api)
            elif (getattr(api, 'Type') == 'Country'):
                Get_Countries(api)
            elif (getattr(api, 'Type') == 'Documents'):
                Get_Documents(api)
            elif (getattr(api, 'Type') == 'Users'):
                Get_Users(api)
            elif (getattr(api, 'Type') == 'Binders'):
                Get_Binders(api)
            elif (getattr(api, 'Type') == 'Monitors'):
                Get_Monitors(api)
            elif (getattr(api, 'Type') == 'Histories'):
                Get_Histories(api)
            elif (getattr(api, 'Type') == 'LoginAuditTrail'):
                Get_LoginAuditTrail(api)

        Save_LastSyncedOn(vaultMaster, '')
