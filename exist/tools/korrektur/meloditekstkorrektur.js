function goto(anchor) {
    if(document.getElementById(anchor)) {
        if(anchor.indexOf("mei") == 0) {
            document.getElementById('mei_end').focus();
        } else {
            document.getElementById('end').focus();
        }
        document.getElementById(anchor).focus();
        document.getElementById(anchor).blur();
    } else {
        //document.getElementById('start').focus();
        alert("Sidenummer " + anchor.replace("mei_","") + " ikke fundet");
    }
}