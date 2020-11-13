import psycopg2

def execute_query(user, password, query):
    conn = psycopg2.connect(
        host="127.0.0.1",
        database="autosalon",
        user=user,
        password=password
    )
    cursor = conn.cursor()
    cursor.execute(query)
    conn.commit()
    conn.close()


def execute_select_query(user, password, query, f_all=True):
    conn = psycopg2.connect(
        host="127.0.0.1",
        database="autosalon",
        user=user,
        password=password
    )
    cursor = conn.cursor()
    cursor.execute(query)
    if f_all:
        data = cursor.fetchall()
    else:
        data = cursor.fetchone()
    conn.close()
    return data