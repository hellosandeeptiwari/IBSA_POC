namespace ODSAutomationUtility
{
    public class FieldDefinitionModel
    {
        public string ObjectName { get; set; }
        public string ObjectAPIName { get; set; }
        public string FieldName { get; set; }
        public string FieldAPIName { get; set; }
        public string DataType { get; set; }
        public bool SCDRequired { get; set; }
    }

    public enum OdsObjectTypeEnum
    {
        Table = 1,
        StoredProcedure = 2
    }

    public class OdsObjectSchemaModel
    {
        public string ObjectName { get; set; }
        public string ObjectScript { get; set; }
        public OdsObjectTypeEnum ObjectType { get; set; }
    }

    public class VeevaOdsFieldMappingModel
    {
        public string OdsTableName { get; set; }
        public string OdsColumnName { get; set; }
        public string VeevaObjectAPIName { get; set; }
        public string VeevaFieldAPIName { get; set; }
        public string DataType { get; set; }
    }
}
