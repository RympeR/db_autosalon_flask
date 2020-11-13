from flask import Flask, render_template, url_for, redirect, request, session, flash, get_flashed_messages, abort
from model import *


app = Flask(__name__)
app.secret_key = 'somesecretkeythatonlyishouldknow'
session_variables = []
role = 'autosalon_guest:guest'

def loadSession(role):
    engine = create_engine(
        f'postgres+psycopg2://{role}@localhost:5432/autosalon', convert_unicode=True)
    # metadata = MetaData()
    db_session = scoped_session(sessionmaker(
        autocommit=False,  autoflush=False, bind=engine))
    metadata = db.metadata
    session_variables.append(engine)
    session_variables.append(db_session)
    session_variables.append(metadata)
    Session = sessionmaker(bind=engine)
    session_ = Session()
    return session_


def shutdown_session(exception=None):
    global session_variables
    session_variables[1].remove()

# --------------404 PAGE------------------
@app.errorhandler(404)
def pageNotFound(error):
    return "<h1>You got 404 mistake please get on correct url adres</h1>"
# ---------------------------------------

# ------------------------LOGIN----------------------------
@app.route('/login', methods=['POST', 'GET'])
def login():
    global role
    if 'login' and 'username' in session:
        if session['login'] == 'staff':
            try:
                shutdown_session()
            except Exception as e:
                pass
            session['login'] = 'autosalon_staff'
            role = 'autosalon_staff:staff'
            return redirect(url_for('admin', username=session['username']))
        elif session['login'] == 'director':
            try:
                shutdown_session()
            except Exception as e:
                pass
            session['login'] = 'autosalon_director'
            role = 'autosalon_director:director'
            return redirect(url_for('director', username=session['username']))
        elif session['login']:
            try:
                shutdown_session()
            except Exception as e:
                pass
            session['login'] = 'autosalon_client'
            role = 'autosalon_client:client'
            return redirect(url_for('client', username=session['username']))

    if request.method == 'POST':
        username = request.form["username"]
        password = request.form['password']
        session_ = loadSession('autosalon_guest:guest')
        query = f"SELECT role_ FROM staff WHERE login = '{username}' AND passw = '{password}' ;"
        print(query)
        try:
            session['login'] = session_.execute(query).fetchone()[0]
        except Exception as e:

            try:
                query = f"SELECT client_id FROM client WHERE login = '{username}' AND passw = '{password}' ;"
                print(query)
                session['login'] = session_.execute(query).fetchone()[0]
                print(session['login'])
                if session['login'] > 0:
                    session['username'] = username
                    role = 'autosalon_staff:staff'
                    return redirect(url_for('client', username=session['username']))
            except Exception as e:
                print(e)
                shutdown_session()
                flash("Неверный логин или пароль")
                return render_template('Registration.html')
            # return f"{e}"

        if session['login'] == 'staff':
            try:
                shutdown_session()
            except Exception as e:
                pass
            session['username'] = username
            role = 'autosalon_staff:staff'
            return redirect(url_for('admin', username=session['username']))
        elif session['login'] == 'director':
            try:
                shutdown_session()
            except Exception as e:
                pass
            session['username'] = username
            role = 'autosalon_director:director'
            return redirect(url_for('director', username=session['username']))
        elif session['login'] == 'client':
            try:
                shutdown_session()
            except Exception as e:
                pass
            session['username'] = username
            role = 'autosalon_client:client'
            return redirect(url_for('client', username=session['username']))
        else:
            flash("Неверный логин или пароль")
            return render_template('Registration.html')

    return render_template('Registration.html')

@app.route('/logout', methods=['POST', 'GET'])
def logout():
    try:
        shutdown_session()
    except Exception as e:
        pass
    try:
        del session['login']
    except Exception as e:
        pass
    try:
        del session['username']
    except Exception as e:
        pass
    print(session)
    return redirect(url_for('login'))

# -------------------------------------------------------------------

@app.route('/director/<username>', methods=['GET'])
def director(username):
    global role
    if 'username' not in session or session['username'] != username:
        abort(401)
    role = "farm_director:director"
    session_ = loadSession(role)
    data1 = session_.execute(
        "SELECT * from sellerc WHERE role_='director';")
    data1 = data1.first()
    print(data1)
    return render_template('director.html', dirstaff=data1, username=session['username'])

@app.route('director/check_cars/<username>/', methods=['POST', 'GET'])
def directorCheckCars(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('director_check_cars.html')

@app.route('director/check_recievers/<username>/', methods=['POST', 'GET'])
def directorCheckRecievers(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('director_check_recievers.html')

@app.route('director/check_staff/<username>/', methods=['POST', 'GET'])
def directorCheckStaff(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('director_check_staff.html')

@app.route('director/salary_changes/<username>/', methods=['POST', 'GET'])
def directorApplySalaryBonuses(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('director_salary_changes.html')

@app.route('director/finance_statistics/<username>/', methods=['POST', 'GET'])
def directorFinanceStatistics(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('director_finance_statistics.html')

@app.route('director/car_order/<username>/', methods=['POST', 'GET'])
def directorOrderCar(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('director_car_order.html')


#------------------------CLIENT-------------------------------
@app.route('/client/<username>')
def client(username):
    if 'username' not in session or session['username'] != username:
        abort(401)

    session_ = loadSession('autosalon_client:client')
    data1 = session_.execute(f"SELECT * from client WHERE login='{username}';")
    data1 = data1.first()
    print(data1)
    return render_template('client.html', dirstaff=data1, username=session['username'])

@app.route('/client/make_order/<username>/', methods=('POST', 'GET'))
def clientMakeOrder(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('client_make_order.html')

@app.route('/client/check_cars/<username>/', methods=('POST', 'GET'))
def clientCheckCars(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('client_cars_check.html')

#-------------------------------------------------------------

#------------------------MANAGER------------------------------
@app.route('/staff/<username>')
def staff(username):
    if 'username' not in session or session['username'] != username:
        abort(401)

    session_ = loadSession('autosalon_client:client')
    data1 = session_.execute(f"SELECT * from client WHERE login='{username}';")
    data1 = data1.first()
    print(data1)
    return render_template('staff.html', dirstaff=data1, username=session['username'])

@app.route('/staff/sell_car/<username>/', methods=('POST', 'GET'))
def staffSellCar(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    return render_template('staff_sell_car.html')

@app.route('/staff/check_cars/<username>/', methods=('POST', 'GET'))
def staffCheckCars(username):
    if 'username' not in session or session['username'] != username:
        abort(401)

    return render_template('staff_cars_check.html')

#-------------------------------------------------------------


# --------------------------BASE PAGES-------------------------------
@app.route('/home')
@app.route('/')
def home():
    return render_template('autosalon_main.html')


if __name__ == "__main__":
    app.run(debug=True)
