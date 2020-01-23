function SetConstructionSign(tile, task) {
    
}

function SetSecondarySign(text) {
    Debug(text);
}

function ClearSecondarySign() {
}

function PutSign (tile, text)
{
    SIGN1 = AISign.BuildSign(tile, text);
}

function ResetSign ()
{
    if (AISign.IsValidSign(SIGN1))
        AISign.RemoveSign(SIGN1);
}
