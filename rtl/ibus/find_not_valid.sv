module find_not_valid(

    input           [3:0]   valid,

    output  logic   [3:0]   result_onehot

);



always_comb begin

    if(~valid[0])

        result_onehot = 4'b0001;

    else if(~valid[1])

        result_onehot = 4'b0010;

    else if(~valid[2])

        result_onehot = 4'b0100;

    else if(~valid[3])

        result_onehot = 4'b1000;

    else

        result_onehot = 4'b0000;

end



// logic [3:0] temp1,temp2;



// assign temp1[0] = valid[0];

// assign temp1[3:1] = temp1[2:0] & valid[3:1];

// assign temp2[0] = temp1[0];

// assign temp2[3:1] = temp1[3:1] ^ temp1[2:0];



// assign result_onehot = {temp2[3:1], ~temp2[0]};



endmodule