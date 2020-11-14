from flask import Flask, render_template, url_for, redirect, request, session, flash, get_flashed_messages, abort
from model import *


app = Flask(__name__)
app.secret_key = 'somesecretkeythatonlyishouldknow'
session_variables = []
role = 'autosalon_guest:guest'

def get_cars(request, login, password):
    try:
            
        query = '''select 
                    modeltype, releasdata,
                    climatcontroltype,
                    audiosystemtype,
                    price, fuel_type,
                    fuelconsumption, colore,
                    enginevolume,
                    fuelconsumption

                    from car
                    join specification using(specification_id)
                    join color using(color_id)
                    join audiosystem using(audiosystem_id)
                    join transmissiontype using(transmissiontype_id)
                    join climatcontrol using(climatcontrol_id)
                    join fueltype using(fueltype_id)
                    where\n
                '''
        if request.form['modeltype'] != '':
            modeltype=request.form['modeltype']
            query +=f"AND modeltype= {modeltype}\n"
        if request.form['releasdata'] != '':
            releasdata=request.form['releasdata']
            query +=f"AND releasdata= {releasdata}\n"
        if request.form['climatcontroltype'] != '':
            climatcontroltype=request.form['climatcontroltype']
            query +=f"AND climatcontroltype= {climatcontroltype}\n"
        if request.form['audiosystemtype'] != '':
            audiosystemtype=request.form['audiosystemtype']
            query +=f"AND audiosystemtype= {audiosystemtype}\n"
        if request.form['price'] != '':
            price=request.form['price']
            query +=f"AND price= {price}\n"
        if request.form['fuel_type'] != '':
            fuel_type=request.form['fuel_type']
            query +=f"AND fuel_type= {fuel_type}\n"
        if request.form['fuelconsumption'] != '':
            fuelconsumption=request.form['fuelconsumption']
            query +=f"AND fuelconsumption= {fuelconsumption}\n"
        if request.form['colore'] != '':
            colore=request.form['colore']
            query +=f"AND colore= {colore}\n"
        if request.form['enginevolume'] != '':
            enginevolume=request.form['enginevolume']
            query +=f"AND enginevolume= {enginevolume}\n"
        if request.form['fuelconsumption'] != '':
            fuelconsumption=request.form['fuelconsumption']
            query +=f"AND fuelconsumption= {fuelconsumption}\n"
        query+=';'
        result = execute_select_query(login, password, query)
        
    except Exception:
        result = ''
    return result

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
            return redirect(url_for('staff', username=session['username']))
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

@app.route('/register', methods=['POST', 'GET'])
def register():
    if 'login' and 'username' in session:
        if session['login'] == 'staff':
            try:
                shutdown_session()
            except Exception as e:
                pass
            session['login'] = 'autosalon_staff'
            role = 'autosalon_staff:staff'
            return redirect(url_for('staff', username=session['username']))
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
        firstname = request.form["firstname"]
        fathername = request.form["fathername"]
        lastname = request.form["lastname"]
        phonenumber = request.form["phonenumber"]
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

@app.route('/director/check_cars/<username>/', methods=['POST', 'GET'])
def directorCheckCars(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        result = get_cars(request, 'autosalon_director', 'director')
    return render_template('director_check_cars.html', username=session['username'], result=result)

@app.route('/director/check_recievers/<username>/', methods=['POST', 'GET'])
def directorCheckRecievers(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        try:
            begin_date = request.form['begin_date']
            end_date = request.form['end_date']
            query = f'''select firstname, lastname, purchasetype, purchasedata, paymenttype, purchaseprice
                        from purchase 
                        join client using(client_id)
                        where purchasedata between '{begin_date}' AND '{end_date}';'''
            result = execute_select_query('autosalon_director', 'director',query)
        except Exception:
            pass
    return render_template('director_check_recievers.html', username=session['username'], result=result)

@app.route('/director/check_staff/<username>/', methods=['POST', 'GET'])
def directorCheckStaff(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        try:
            query = 'select * from staff_info;'
            result = execute_select_query('autosalon_director', 'director',query)
        except Exception:
            pass
    return render_template('director_check_staff.html', username=session['username'], result=result)

@app.route('/director/salary_changes/<username>/', methods=['POST', 'GET'])
def directorApplySalaryBonuses(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        try:
            staff_id = request.form['staff_id']
            query = f'select * from upply_salary_bonuses({staff_id})'
            execute_query('autosalon_director', 'director', query)
        except Exception:
            pass
    return render_template('director_salary_changes.html', username=session['username'])

@app.route('/director/add_staff/<username>')
def directorAddStaff(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        try:
            first_name = request.form['first_name']
            father_name = request.form['father_name']
            last_name = request.form['last_name']
            phone_number = request.form['phone_number']
            passport_number = request.form['passport_number']
            inn = request.form['inn']
            query = f'''insert into sellers(first_name, father_name, last_name, phone_number, passport_number, inn)
                            values('{first_name}','{father_name}','{last_name}','{phone_number}','{passport_number}','{inn}');'''
            execute_query('autosalon_director', 'director', query)
        except Exception:
            pass
    return render_template('director_add_staff.html', username=session['username'])


@app.route('/director/finance_statistics/<username>/', methods=['POST', 'GET'])
def directorFinanceStatistics(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        try:
            begin_date = request.form['begin_date']
            end_date = request.form['end_date']
            query = f'''select * form statistics_info
                            where paymentsdate between {begin_date} and {end_date};'''
        except Exception:
            pass
    return render_template('director_finance_statistics.html', username=session['username'])

@app.route('/director/car_order/<username>/', methods=['POST', 'GET'])
def directorOrderCar(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        try:
            query = ''
        except Exception:
            pass
    return render_template('director_car_order.html', username=session['username'])


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
    if request.method == 'POST':
        try:
            purchasetype = request.form["purchasetype"]
            model_type = request.form["model_type"]
            color = request.form["color"]
            payment_type = request.form["payment_type"]
            last_name = request.form["last_name"]
            phone_number = request.form["phone_number"]
            seller_id = request.form["seller_id"]

            query = f"select addpurchase('{purchasetype}', '{model_type}', '{color}', '{payment_type}', '{last_name}', '{phone_number}', {seller_id});"
            execute_query('autosalon_client', 'client', query)
        except Exception:
            pass
    return render_template('client_make_order.html', username=session['username'])

@app.route('/client/check_cars/<username>/', methods=('POST', 'GET'))
def clientCheckCars(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        result = get_cars(request, 'autosalon_client', 'client')
    return render_template('client_cars_check.html', result=result, username=session['username'])

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
    if request.method == 'POST':
        try:
            query = ''
        except Exception:
            pass
    return render_template('staff_sell_car.html', username=session['username'])

@app.route('/staff/check_cars/<username>/', methods=('POST', 'GET'))
def staffCheckCars(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        result = get_cars(request, 'autosalon_staff', 'staff')
    return render_template('client_cars_check.html', result, username=session['username'])

#-------------------------------------------------------------


# --------------------------BASE PAGES-------------------------------
@app.route('/home')
@app.route('/')
def home():
    return render_template('autosalon_main.html')


if __name__ == "__main__":
    app.run(debug=True)
