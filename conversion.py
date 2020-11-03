import sys
from pyliftover import LiftOver

chainfile = sys.argv[1]
in_coord = sys.argv[2]

lo = LiftOver(chainfile)
in_chr, in_pos = in_coord.split(':')
conversions = lo.convert_coordinate(in_chr, int(in_pos))

if not conversions:
    print('No conversion found.')
else:
    for conv in conversions:
        print(conv[0] + ':' + str(conv[1]) + '\t' + conv[2] + '\t' + str(conv[3]))