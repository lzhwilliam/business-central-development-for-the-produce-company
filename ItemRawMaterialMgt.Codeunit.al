codeunit 50102 "Item Raw Material Mgt."
{
    Access = Internal;

    // Inherent execute: no permission set is needed to run this codeunit, and a
    // security administrator cannot switch that off. (Inherent permissions can
    // only be granted on this extension's own objects, so the base-table access
    // below is elevated through the Permissions property instead.)
    InherentEntitlements = X;
    InherentPermissions = X;

    // The codeunit itself carries the data access it needs, so callers only need
    // indirect rights on these tables (the normal "run it through a codeunit"
    // pattern). No permission set ships with this extension.
    Permissions =
        tabledata Item = RM,
        tabledata "Production BOM Line" = R;

    /// <summary>
    /// TRUE for items whose "No." starts with RM, ING or PKG. Such items never
    /// receive raw-material data and the Item Ingredients FastTab is hidden for them.
    /// </summary>
    procedure IsMaterialItem(ItemNo: Code[20]): Boolean
    var
        MaterialPrefixes: List of [Text];
        Prefix: Text;
        UpperItemNo: Text;
    begin
        MaterialPrefixes.Add('RM');
        MaterialPrefixes.Add('ING');
        MaterialPrefixes.Add('PKG');

        UpperItemNo := UpperCase(ItemNo);
        foreach Prefix in MaterialPrefixes do
            if UpperItemNo.StartsWith(Prefix) then
                exit(true);
        exit(false);
    end;

    /// <summary>
    /// Batch entry point. Re-derives the raw-material fields for every eligible
    /// item from its production BOM. Returns the number of items actually changed.
    /// </summary>
    procedure UpdateRawMaterialsForAllItems() UpdatedCount: Integer
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("No.", "Production BOM No.");
        if Item.FindSet(true) then
            repeat
                if UpdateRawMaterials(Item) then
                    UpdatedCount += 1;
            until Item.Next() = 0;
    end;

    /// <summary>
    /// Re-derives "Raw Material 1".."Raw Material 9" for a single item from its
    /// production BOM and persists the change. Returns TRUE only when a value
    /// actually changed. Items with a material prefix, without a production BOM,
    /// or without any RM component lines are left untouched.
    /// </summary>
    procedure UpdateRawMaterials(var Item: Record Item): Boolean
    var
        Descriptions: array[9] of Text[100];
    begin
        if IsMaterialItem(Item."No.") then
            exit(false);
        if Item."Production BOM No." = '' then
            exit(false);
        if not CollectRawMaterials(Item."Production BOM No.", Descriptions) then
            exit(false);
        exit(ApplyRawMaterials(Item, Descriptions));
    end;

    /// <summary>
    /// Card helper: loads a fresh Item record (never the page's Rec) and syncs it.
    /// </summary>
    procedure SyncItem(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(false);
        exit(UpdateRawMaterials(Item));
    end;

    /// <summary>
    /// Fills Descriptions[1..9] with the descriptions of the production BOM's
    /// RM* component items, highest "Quantity per" first. Returns FALSE when the
    /// BOM has no such lines.
    /// All BOM versions / statuses are scanned and deduped by component, keeping
    /// the highest "Quantity per" seen; narrow to the active certified version
    /// here if that is ever required.
    /// </summary>
    local procedure CollectRawMaterials(ProductionBOMNo: Code[20]; var Descriptions: array[9] of Text[100]): Boolean
    var
        ProdBOMLine: Record "Production BOM Line";
        ComponentItem: Record Item;
        QtyPerByComponent: Dictionary of [Text, Decimal];
        SortedComponents: List of [Text];
        ComponentNo: Text;
        ExistingQtyPer: Decimal;
        Index: Integer;
    begin
        Clear(Descriptions);

        ProdBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetFilter("No.", 'RM*');
        if not ProdBOMLine.FindSet() then
            exit(false);

        repeat
            if QtyPerByComponent.Get(ProdBOMLine."No.", ExistingQtyPer) then begin
                if ProdBOMLine."Quantity per" > ExistingQtyPer then
                    QtyPerByComponent.Set(ProdBOMLine."No.", ProdBOMLine."Quantity per");
            end else
                QtyPerByComponent.Set(ProdBOMLine."No.", ProdBOMLine."Quantity per");
        until ProdBOMLine.Next() = 0;

        SortedComponents := SortByQtyPerDescending(QtyPerByComponent);

        foreach ComponentNo in SortedComponents do begin
            Index += 1;
            if Index > ArrayLen(Descriptions) then
                exit(true);
            if ComponentItem.Get(ComponentNo) then
                Descriptions[Index] := CopyStr(ComponentItem.Description, 1, MaxStrLen(Descriptions[Index]))
            else
                Descriptions[Index] := CopyStr(ComponentNo, 1, MaxStrLen(Descriptions[Index]));
        end;

        exit(true);
    end;

    local procedure SortByQtyPerDescending(QtyPerByComponent: Dictionary of [Text, Decimal]) Sorted: List of [Text]
    var
        ComponentNo: Text;
        InsertAt: Integer;
        i: Integer;
    begin
        foreach ComponentNo in QtyPerByComponent.Keys() do begin
            InsertAt := Sorted.Count() + 1;
            for i := 1 to Sorted.Count() do
                if RanksBefore(ComponentNo, Sorted.Get(i), QtyPerByComponent) then begin
                    InsertAt := i;
                    break;
                end;
            if InsertAt > Sorted.Count() then
                Sorted.Add(ComponentNo)
            else
                Sorted.Insert(InsertAt, ComponentNo);
        end;
    end;

    local procedure RanksBefore(CandidateNo: Text; ExistingNo: Text; QtyPerByComponent: Dictionary of [Text, Decimal]): Boolean
    var
        CandidateQty: Decimal;
        ExistingQty: Decimal;
    begin
        CandidateQty := QtyPerByComponent.Get(CandidateNo);
        ExistingQty := QtyPerByComponent.Get(ExistingNo);
        if CandidateQty <> ExistingQty then
            exit(CandidateQty > ExistingQty);
        exit(CandidateNo < ExistingNo);
    end;

    local procedure ApplyRawMaterials(var Item: Record Item; Descriptions: array[9] of Text[100]) Changed: Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FirstFieldNo: Integer;
        CurrentValue: Text;
        i: Integer;
    begin
        FirstFieldNo := Item.FieldNo("Raw Material 1");
        RecRef.GetTable(Item);
        for i := 1 to ArrayLen(Descriptions) do begin
            FieldRef := RecRef.Field(FirstFieldNo + i - 1);
            CurrentValue := Format(FieldRef.Value());
            if CurrentValue <> Descriptions[i] then begin
                FieldRef.Value := Descriptions[i];
                Changed := true;
            end;
        end;

        if Changed then begin
            RecRef.SetTable(Item);
            Item.Modify(true);
        end;
    end;
}
