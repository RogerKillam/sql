DECLARE @xmlTest XML = '<?xml version="1.0" encoding="UTF-8"?>
                        <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                            xmlns:ns1="urn:dictionary:com.chargepoint.webservices">
                            <SOAP-ENV:Body>
                                <ns1:getStationGroupsResponse>
                                    <responseCode>100</responseCode>
                                    <responseText>API input request executed successfully.</responseText>
                                    <groupData>
                                        <sgID>26103</sgID>
                                        <orgID>1:ORG00509</orgID>
                                        <sgName>Charlotte AP1</sgName>
                                        <organizationName>Microsoft</organizationName>
                                        <stationData>
                                            <stationID>1:3569471</stationID>
                                            <Geo>
                                                <Lat>35.138344000000000</Lat>
                                                <Long>-80.922226000000000</Long>
                                            </Geo>
                                        </stationData>
                                    </groupData>
                                </ns1:getStationGroupsResponse>
                            </SOAP-ENV:Body>
                        </SOAP-ENV:Envelope>';

SELECT [sgID] = R.value('sgID[1]', 'varchar(max)')
    , [orgID] = R.value('orgID[1]', 'varchar(max)')
    , [sgName] = R.value('sgName[1]', 'varchar(max)')
    , [organizationName] = R.value('organizationName[1]', 'varchar(max)')
    , [stationID] = R.value('stationData[1]/././stationID[1]', 'varchar(max)')
    , [Lat] = R.value('stationData[1]/././Geo[1]/Lat[1]', 'varchar(max)')
    , [Long] = R.value('stationData[1]/././Geo[1]/Long[1]', 'varchar(max)')
FROM @xmlTest.nodes('//*:groupData') AS A(R)
GO
