port_p0 = 0;
port_p1 = 1;
port_p2 = 2;
port_p3 = 3;
message = "";

// This function is called when time (t-states) advances.
API.tick = () => {
}

// This function is called when an 'out' is executed in Z80.
API.writePort = (port, value) => {
    // Go through all ports
    if (port == 0x9000) {
        if (value != 0) {
            message += String.fromCharCode(value);
         } else {
            API.log("> " + message);
            message = "";
         }
    } else if (port == 0x82) {
        port_p0 = value;
    } else if (port == 0xA2) {
        port_p1 = value;
    } else if (port == 0xC2) {
        port_p2 = value;
    } else if (port == 0xE2) {
        port_p3 = value;
    }
}


API.readPort = (port) => {
    if (port == 0x82) {
        return port_p0;
    } else if (port == 0xA2) {
        return port_p1;
    } else if (port == 0xC2) {
        return port_p2;
    } else if (port == 0xE2) {
        return port_p3;
    }
}

