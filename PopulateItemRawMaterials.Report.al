report 50103 "Populate Item Raw Materials"
{
    Caption = 'Populate Item Raw Materials';
    ProcessingOnly = true;
    UseRequestPage = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    // Runnable by any user regardless of license / permission sets (see the codeunit).
    InherentEntitlements = X;
    InherentPermissions = X;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Production BOM No.", "Item Category Code";

            trigger OnPreDataItem()
            begin
                Item.SetFilter("No.", '<>RM*&<>ING*&<>PKG*');
            end;

            trigger OnAfterGetRecord()
            begin
                // The Item read here is a plain report iteration; the elevated
                // Item modify / Production BOM Line read happen inside the codeunit,
                // whose procedures carry their own inherent permissions.
                if RawMatMgt.UpdateRawMaterials(Item) then
                    UpdatedCount += 1;
            end;

            trigger OnPostDataItem()
            begin
                Message(UpdatedMsg, UpdatedCount);
            end;
        }
    }

    var
        RawMatMgt: Codeunit "Item Raw Material Mgt.";
        UpdatedCount: Integer;
        UpdatedMsg: Label '%1 item(s) updated.', Comment = '%1 = number of items whose raw-material fields changed';
}
