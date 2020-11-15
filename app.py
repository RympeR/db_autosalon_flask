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
                    enginevolume

                    from car
                    join specification using(specification_id)
                    join color using(color_id)
                    join audiosystem using(audiosystem_id)
                    join transmissiontype using(transmissiontype_id)
                    join climatcontrol using(climatcontrol_id)
                    join fueltype using(fueltype_id)'''
        if request.form['modeltype'] != '':
            if 'where' not in query:
                query+='\nwhere'
            modeltype=request.form['modeltype']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nand modeltype= '{modeltype}'"
            else:
                query +=f"\nmodeltype= '{modeltype}'"
        if request.form['releasdata'] != '':
            if 'where' not in query:
                query+='\nwhere'
            releasdata=request.form['releasdata']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND releasdata= '{releasdata}'"
            else:
                query +=f"\nreleasdata= '{releasdata}'"
        if request.form['climatcontroltype'] != 'empty':
            if 'where' not in query:
                query+='\nwhere'
            climatcontroltype=request.form['climatcontroltype']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND climatcontrol_id= {climatcontroltype}"
            else:
                query +=f"\nclimatcontrol_id= {climatcontroltype}"
        if request.form['audiosystemtype'] != 'empty':
            if 'where' not in query:
                query+='\nwhere'
            audiosystemtype=request.form['audiosystemtype']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND audiosystem_id= {audiosystemtype}"
            else:
                query +=f"\naudiosystem_id= {audiosystemtype}"
        if request.form['price'] != '':
            if 'where' not in query:
                query+='\nwhere'
            price=request.form['price']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND price= {price}"
            else:
                query +=f"\nprice= {price}"
        if request.form['fuel_type'].strip()!= 'empty':
            if 'where' not in query:
                query+='\nwhere'
            fuel_type=request.form['fuel_type']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND fueltype_id= {fuel_type}"
            else:
                query +=f"\nfueltype_id= {fuel_type}"
        if request.form['fuelconsumption'] != '':
            if 'where' not in query:
                query+='\nwhere'
            fuelconsumption=request.form['fuelconsumption']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND fuelconsumption= '{fuelconsumption}'"
            else:
                query +=f"\nfuelconsumption= '{fuelconsumption}'"
        if request.form['colore'] != 'empty':
            if 'where' not in query:
                query+='\nwhere'
            colore=request.form['colore']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND color_id= {colore}"
            else:
                query +=f"\ncolor_id= {colore}"
        if request.form['enginevolume'] != '':
            if 'where' not in query:
                query+='\nwhere'
            enginevolume=request.form['enginevolume']
            if query.split('\n')[-1].strip()!='where':
                query +=f"\nAND enginevolume= {enginevolume}"
            else:
                query +=f"\nenginevolume= {enginevolume}"
        query+=';'
        result = execute_select_query(login, password, query)
        
    except Exception as e:
        print(e)
        query = '''select 
                    modeltype, releasdata,
                    climatcontroltype,
                    audiosystemtype,
                    price, fuel_type,
                    fuelconsumption, colore,
                    enginevolume

                    from car
                    join specification using(specification_id)
                    join color using(color_id)
                    join audiosystem using(audiosystem_id)
                    join transmissiontype using(transmissiontype_id)
                    join climatcontrol using(climatcontrol_id)
                    join fueltype using(fueltype_id);    
                '''
        result = execute_select_query(login, password, query)
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
        query = f"SELECT role_ FROM sellers WHERE login = '{username}' AND passw = '{password}' ;"
        print(query)
        try:
            session['login'] = execute_select_query('autosalon_guest', 'guest', query,f_all=False)[0].replace('\n','')
            print(session['login'])
        except Exception as e:
            print(e)
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
            return redirect(url_for('staff', username=session['username']))
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
        query = f"""
            insert into client(firstname, fathername, lastname, phonenumber, login, passw)
            values('{firstname}','{fathername}','{lastname}','{phonenumber}','{username}','{password}');
        """
        print(query)
        try:
            execute_query('autosalon_guest', 'guest', query)
            session['login'] = 'autosalon_client'
            session['username'] = username
            return redirect(url_for('client', username=session['username']))
        except Exception as e:
            print(e)
            flash('Такой логин уже есть')
    return render_template('register_page.html')

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
    role = "autosalon_director:director"
    session_ = loadSession(role)
    data1 = session_.execute("SELECT * from sellers WHERE role_='director';")
    data1 = data1.first()
    print(data1)
    return render_template('director.html', dirstaff=data1, username=session['username'])

@app.route('/director/check_cars/<username>/', methods=['POST', 'GET'])
def directorCheckCars(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    result=''
    audiosystems = execute_select_query(
        'autosalon_director',
        'director',
        'SELECT * FROM audioSystem;'
    )
    climatcontroltypes = execute_select_query(
        'autosalon_director',
        'director',
        'SELECT * FROM climatcontrol;'
    )
    fuel_types = execute_select_query(
        'autosalon_director',
        'director',
        'SELECT * FROM fueltype;'
    )
    colores = execute_select_query(
        'autosalon_director',
        'director',
        'SELECT * FROM color;'
    )

    
    if request.method == 'POST':
        result = get_cars(request, 'autosalon_director', 'director')
    return render_template(
        'director_check_cars.html', 
        username=session['username'],
        audiosystems=audiosystems,
        climatcontroltypes=climatcontroltypes,
        fuel_types=fuel_types,
        colores=colores,
        result=result
        )

@app.route('/director/check_recievers/<username>/', methods=['POST', 'GET'])
def directorCheckRecievers(username):
    result=''
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
    result=''

    if 'username' not in session or session['username'] != username:
        abort(401)
    
    try:
        query = 'select * from staff_info;'
        result = execute_select_query('autosalon_director', 'director',query)
    except Exception as e:
        print(e)
    return render_template('director_check_staff.html', username=session['username'], result=result)

@app.route('/director/salary_changes/<username>/', methods=['POST', 'GET'])
def directorApplySalaryBonuses(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    if request.method == 'POST':
        try:
            staff_id = request.form['staff_id']
            query = f'select * from upply_salary_bonuses({staff_id});'
            execute_query('autosalon_director', 'director', query)
            url_for('directorCheckStaff', username=session['username'])
        except Exception:
            pass
    return render_template('director_salary_changes.html', username=session['username'])

@app.route('/director/add_staff/<username>/')
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
            login = request.form['login']
            passw = request.form['passw']
            query = f'''insert into sellers(first_name, father_name, last_name, phone_number, passport_number, inn, login, passw, role_)
                            values('{first_name}','{father_name}','{last_name}','{phone_number}','{passport_number}','{inn}','{login}','{passw}','staff');'''
            execute_query('autosalon_director', 'director', query)
            url_for('directorCheckStaff', username=session['username'])
        except Exception:
            pass
    return render_template('director_add_staff.html', username=session['username'])


@app.route('/director/finance_statistics/<username>/', methods=['POST', 'GET'])
def directorFinanceStatistics(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    result=''
    if request.method == 'POST':
        try:
            begin_date = request.form['begin_date']
            end_date = request.form['end_date']
            query = f'''select * from statistics_info
                            where purchasedata between '{begin_date}' and '{end_date}';'''
            result = execute_select_query('autosalon_director', 'director', query)
        except Exception as e:
            print(e)
    return render_template('director_finance_statistics.html',result=result, username=session['username'])

@app.route('/director/car_order/<username>/', methods=['POST', 'GET'])
def directorOrderCar(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    colores = execute_select_query(
        'autosalon_director',
        'director',
        'SELECT * FROM color;'
    )
    staff = execute_select_query(
        'autosalon_director',
        'director',
        'SELECT * FROM sellers;'
    )
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
        except Exception as e:
            print(e)
    return render_template(
        'director_car_order.html',
        colores=colores,
        staff=staff,
        username=session['username'])


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
    colores = execute_select_query(
        'autosalon_client',
        'client',
        'SELECT * FROM color;'
    )
    staff = execute_select_query(
        'autosalon_staff',
        'staff',
        'SELECT * FROM sellers;'
    )
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
    return render_template(
        'client_make_order.html',
        colores=colores, 
        staff=staff, 
        username=session['username']
        )

@app.route('/client/check_cars/<username>/', methods=('POST', 'GET'))
def clientCheckCars(username):
    result=''
    if 'username' not in session or session['username'] != username:
        abort(401)
    audiosystems = execute_select_query(
        'autosalon_client',
        'client',
        'SELECT * FROM audioSystem;'
    )
    climatcontroltypes = execute_select_query(
        'autosalon_client',
        'client',
        'SELECT * FROM climatcontrol;'
    )
    fuel_types = execute_select_query(
        'autosalon_client',
        'client',
        'SELECT * FROM fueltype;'
    )
    colores = execute_select_query(
        'autosalon_client',
        'client',
        'SELECT * FROM color;'
    )

    
    if request.method == 'POST':
        
        result = get_cars(request, 'autosalon_client', 'client')
    return render_template(
        'client_cars_check.html', 
        username=session['username'],
        audiosystems=audiosystems,
        climatcontroltypes=climatcontroltypes,
        fuel_types=fuel_types,
        colores=colores,
        result=result
        )
#-------------------------------------------------------------

#------------------------MANAGER------------------------------
@app.route('/staff/<username>')
def staff(username):
    if 'username' not in session or session['username'] != username:
        abort(401)

    session_ = loadSession('autosalon_staff:staff')
    data1 = session_.execute(f"SELECT * from sellers WHERE login='{username}';")
    data1 = data1.first()
    print(data1)
    return render_template('staff.html', dirstaff=data1, username=session['username'])

@app.route('/staff/sell_car/<username>/', methods=('POST', 'GET'))
def staffSellCar(username):
    if 'username' not in session or session['username'] != username:
        abort(401)
    colores = execute_select_query(
        'autosalon_staff',
        'staff',
        'SELECT * FROM color;'
    )
    staff = execute_select_query(
        'autosalon_staff',
        'staff',
        'SELECT * FROM sellers;'
    )
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
    return render_template(
        'staff_sell_car.html',
        staff=staff,
        colores=colores,
        username=session['username'])

@app.route('/staff/check_cars/<username>/', methods=('POST', 'GET'))
def staffCheckCars(username):
    result=''
    if 'username' not in session or session['username'] != username:
        abort(401)
    audiosystems = execute_select_query(
        'autosalon_staff',
        'staff',
        'SELECT * FROM audioSystem;'
    )
    climatcontroltypes = execute_select_query(
        'autosalon_staff',
        'staff',
        'SELECT * FROM climatcontrol;'
    )
    fuel_types = execute_select_query(
        'autosalon_staff',
        'staff',
        'SELECT * FROM fueltype;'
    )
    colores = execute_select_query(
        'autosalon_staff',
        'staff',
        'SELECT * FROM color;'
    )

    
    if request.method == 'POST':
        result = get_cars(request, 'autosalon_staff', 'staff')
    return render_template(
        'staff_cars_check.html', 
        username=session['username'],
        audiosystems=audiosystems,
        climatcontroltypes=climatcontroltypes,
        fuel_types=fuel_types,
        colores=colores,
        result=result
        )
        

#-------------------------------------------------------------


# --------------------------BASE PAGES-------------------------------
@app.route('/home')
@app.route('/')
def home():
    return render_template('autosalon_main.html')


if __name__ == "__main__":
    app.run(debug=True)
