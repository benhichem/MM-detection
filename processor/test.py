from cgi import print_arguments
from DLAC import Model
import sys

args = sys.argv
print(args)
path = args[1]

#distination = "path_to_file/output.csv"


model = Model(path)
# model.predict_to_terminal(threshold=0.99)   # 0.99 is recommended with the bigger model
model.predict_to_csv(threshold=0.99, out_file="predictions.csv")
