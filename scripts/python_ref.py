import numpy as np
import random


def mat_vec_mul(matrix, vector):
    matrix = np.array(matrix, dtype=np.int8) #8 bit matrix
    vector = np.array(vector, dtype=np.int8) #8 bit vector
    return matrix.astype(np.int32) @ vector.astype(np.int32) #dot product


def run_random_tests(n=10):
    for i in range(n):
        matrix = np.random.randint(-128, 128, size=(4, 4), dtype=np.int8)
        vector = np.random.randint(-128, 128, size=4, dtype=np.int8)
        result = mat_vec_mul(matrix, vector)
        print(f"Test {i+1}: matrix={matrix} vector={vector} result={result.tolist()}")

run_random_tests(10)



"""
#tests
#identity matrix
matrix1 = [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
vector1 = [1,2,3,4]
print("test 1: ", mat_vec_mul(matrix1, vector1))  # [1,2,3,4]

#all ones 
matrix1 = [[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]]
vector1 = [1,1,1,1]
print("test 2: ", mat_vec_mul(matrix1, vector1))  # [4,4,4,4]

#negative weights
matrix1 = [[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]]
vector1 = [1,1,1,1]
print("test 3: ", mat_vec_mul(matrix1, vector1))  # [-4,-4,-4,-4]
"""

