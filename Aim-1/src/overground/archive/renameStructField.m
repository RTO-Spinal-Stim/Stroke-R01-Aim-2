function s = renameStructField(s, oldFieldName, newFieldName)
    [s.(newFieldName)] = s.(oldFieldName);
    s = rmfield(s, oldFieldName);
end