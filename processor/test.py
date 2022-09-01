from cgi import print_arguments
from DLAC import Model
import sys

args = sys.argv

path = "./dist/Downloads/"+args[1]
distination = "./dist/Downloads/"+args[1][:-1]+".csv"


model = Model(path)
# model.predict_to_terminal(threshold=0.99)   # 0.99 is recommended with the bigger model
model.predict_to_csv(threshold=0.99, out_file=distination)
