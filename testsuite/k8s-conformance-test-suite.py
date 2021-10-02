# Set the following environment variables to run the test suite

# Common Variables
# Some of the variables need to be populated from the service principal and storage account details provided to you by Microsoft

import random
import string

res = ''.join(random.choices(string.ascii_uppercase + string.digits, k = 7))
print(res)