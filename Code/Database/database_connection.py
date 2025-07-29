# Copyright (c) 2025 Kemar Christie & Roberto James
# All rights reserved. Unauthorized use, copying, or distribution is prohibited.
# Contact kemar.christie@yahoo.com & robertojames91@gmail.com for licensing inquiries.
# Authors: Kemar Christie & Roberto James

import mysql.connector
from mysql.connector import Error
import tkinter.messagebox as messagebox

def get_db_connection():
    try:

        # Attempt to establish a connection to the online MySQL database
        dbConn = mysql.connector.connect(host="localhost",user="root",password="",database="sql5741398")
        
        # Check if the connection was successful
        if dbConn.is_connected():
            return dbConn
    except Error as e:
        # Print an error message if the connection failed
        #F-strings allow you to embed expressions inside string literals by enclosing them in curly braces {}
        messagebox.showerror("Validation Error", f"Error connecting to the database: {e}")
        return None

    
