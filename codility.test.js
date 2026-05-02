const Generator = {
    generateIPAddresses(number) {
        const strNumber = String(number);
        const numLength = strNumber.length;

        if (numLength < 4 || numLength > 12) {
            return [];
        }

        const ipAddresses = [];
        const nL1 = numLength - 3;
        const nL2 = numLength - 2;
        const nL3 = numLength - 1;
        const nL4 = numLength;

        for (let i = 1; i <= nL1; i++) {
            for (let j = i + 1; j <= nL2; j++) {
                for (let k = j + 1; k <= nL3; k++) {
                    for (let l = k + 1; l <= nL4; l++) {
                        const octet1 = Number(strNumber.slice(0, i));
                        const octet2 = Number(strNumber.slice(i, j));
                        const octet3 = Number(strNumber.slice(j, k));
                        const octet4 = Number(strNumber.slice(k, l));

                        const str = `${octet1}${octet2}${octet3}${octet4}`;

                        if (
                            octet1 <= 255 &&
                            octet2 <= 255 &&
                            octet3 <= 255 &&
                            octet4 <= 255 &&
                            str.length === numLength
                        ) {
                            const ipAddress = `${octet1}.${octet2}.${octet3}.${octet4}`;
                            ipAddresses.push(ipAddress);
                        }
                    }
                }
            }
        }

        return ipAddresses;
    }
};

console.log(Generator.generateIPAddresses(123456));
