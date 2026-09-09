pageextension 50101 "Item Card Extension " extends "Item Card"
{
    layout
    {
        addlast(content)
        {
            group(ItemIngredients)
            {
                Caption = 'Item Ingredients';
                Visible = ShowGroup;

                group(RawMaterial)
                {
                    Caption = 'Raw Material';

                    field("Raw Material 1"; Rec."Raw Material 1") { ApplicationArea = All; ToolTip = 'Specifies raw material 1 for the item.'; }
                    field("Raw Material 2"; Rec."Raw Material 2") { ApplicationArea = All; ToolTip = 'Specifies raw material 2 for the item.'; }
                    field("Raw Material 3"; Rec."Raw Material 3") { ApplicationArea = All; ToolTip = 'Specifies raw material 3 for the item.'; }
                    field("Raw Material 4"; Rec."Raw Material 4") { ApplicationArea = All; ToolTip = 'Specifies raw material 4 for the item.'; }
                    field("Raw Material 5"; Rec."Raw Material 5") { ApplicationArea = All; ToolTip = 'Specifies raw material 5 for the item.'; }
                    field("Raw Material 6"; Rec."Raw Material 6") { ApplicationArea = All; ToolTip = 'Specifies raw material 6 for the item.'; }
                    field("Raw Material 7"; Rec."Raw Material 7") { ApplicationArea = All; ToolTip = 'Specifies raw material 7 for the item.'; }
                    field("Raw Material 8"; Rec."Raw Material 8") { ApplicationArea = All; ToolTip = 'Specifies raw material 8 for the item.'; }
                    field("Raw Material 9"; Rec."Raw Material 9") { ApplicationArea = All; ToolTip = 'Specifies raw material 9 for the item.'; }
                }

                group(Yield)
                {
                    Caption = 'Yield';

                    field("Yield 1"; Rec."Yield 1") { ApplicationArea = All; ToolTip = 'Specifies yield 1 for the item.'; }
                    field("Yield 2"; Rec."Yield 2") { ApplicationArea = All; ToolTip = 'Specifies yield 2 for the item.'; }
                    field("Yield 3"; Rec."Yield 3") { ApplicationArea = All; ToolTip = 'Specifies yield 3 for the item.'; }
                    field("Yield 4"; Rec."Yield 4") { ApplicationArea = All; ToolTip = 'Specifies yield 4 for the item.'; }
                    field("Yield 5"; Rec."Yield 5") { ApplicationArea = All; ToolTip = 'Specifies yield 5 for the item.'; }
                    field("Yield 6"; Rec."Yield 6") { ApplicationArea = All; ToolTip = 'Specifies yield 6 for the item.'; }
                    field("Yield 7"; Rec."Yield 7") { ApplicationArea = All; ToolTip = 'Specifies yield 7 for the item.'; }
                    field("Yield 8"; Rec."Yield 8") { ApplicationArea = All; ToolTip = 'Specifies yield 8 for the item.'; }
                    field("Yield 9"; Rec."Yield 9") { ApplicationArea = All; ToolTip = 'Specifies yield 9 for the item.'; }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        SyncedValues: Boolean;
    begin
        // Inline prefix check so the Item Card always opens, even if the user has
        // not been granted execute permission on codeunit "Item Raw Material Mgt.".
        ShowGroup := not IsMaterialItemNo(Rec."No.");

        if ShowGroup and (Rec."No." <> '') and (Rec."No." <> LastSyncedItemNo) then begin
            LastSyncedItemNo := Rec."No.";
            // Wrapped: a permission / data problem degrades to "no refresh",
            // it does not stop the card from opening.
            if TrySyncItem(Rec."No.", SyncedValues) and SyncedValues then
                CurrPage.Update(false);
        end;
    end;

    [TryFunction]
    local procedure TrySyncItem(ItemNo: Code[20]; var Updated: Boolean)
    begin
        Updated := RawMatMgt.SyncItem(ItemNo);
    end;

    local procedure IsMaterialItemNo(ItemNo: Code[20]): Boolean
    var
        UpperItemNo: Text;
    begin
        UpperItemNo := UpperCase(ItemNo);
        exit(UpperItemNo.StartsWith('RM') or UpperItemNo.StartsWith('ING') or UpperItemNo.StartsWith('PKG'));
    end;

    var
        RawMatMgt: Codeunit "Item Raw Material Mgt.";
        ShowGroup: Boolean;
        LastSyncedItemNo: Code[20];
}
