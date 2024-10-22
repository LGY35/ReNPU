
data = []
byte_cnt = 0
with open("./case3_corerd.txt","r") as f:
    for line in f.readlines():
        line = line.strip("\n")
        line = line.split()

        if line[0][0] == '@':
            while(byte_cnt < int(line[0][1:9],16)):
                if(byte_cnt%16 == 15):
                    data.append('00\n')
                    # data.append('')
                else:
                    data.append('00 ')
                byte_cnt = byte_cnt + 1
            if(byte_cnt > int(line[0][1:9],16)):
                print('padding error')
            # data.append('\n')
            # for i in line:
            #     if(byte_cnt%16 == 15):
            #         data.append(i)
            #         data.append('\n')
            #     else:
            #         data.append(i)
            #     byte_cnt = byte_cnt + 1
        else:
            for i in line:
                if(byte_cnt%16 == 15):
                    data.append(i + '\n')
                    # data.append('\n')
                else:
                    data.append(i + ' ')
                    # data.append(' ')
                byte_cnt = byte_cnt + 1

data_base_addr = 16384

while(byte_cnt < data_base_addr):
    if(byte_cnt%16 == 15):
        data.append('00\n')
        # data.append('')
    else:
        data.append('00 ')
    byte_cnt = byte_cnt + 1
    # print('hit')

with open("./case9_data.txt","r") as fdata:
        for line in fdata.readlines():
            line = line.strip("\n")
            for i in range(32):
                if(byte_cnt%16 == 15):
                    data.append(line[i*2:i*2+2] + '\n')
                    # data.append('\n')
                else:
                    data.append(line[i*2:i*2+2] + ' ')
                byte_cnt = byte_cnt + 1

fout = open('hex_all.txt','+w')
# for i in range(byte_cnt):
#     if(i%16 == 15):
#         fout.write(data[i])
#         # fout.write('\n')
#     else:
#         fout.write(data[i])
for i in data:
    fout.write(i)
fout.close()

f.close()
fdata.close()
