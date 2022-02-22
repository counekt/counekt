# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, request, current_app
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import app.routes.auth.funcs as funcs
from app.routes.errors.custom import token_is_expired_error, email_not_sent_error
from app import db, models
from app.routes.auth import bp
import json
from datetime import date
import smtplib


@ bp.route("/register/", methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for("index.index"))

    user = None

    if request.method == 'POST':
        step = request.form.get("step")

        if step == "step-1":
            month = request.form.get('month')
            day = request.form.get('day')
            year = request.form.get('year')

            gender = request.form.get('gender')

            response = funcs.verify_traits(month=month, day=day, year=year, gender=gender)
            if response:
                return response
            return json.dumps({'status': 'success'})

        elif step == "step-2":
            username = request.form.get("username")
            email = request.form.get("email")

            response = funcs.verify_identifiers(username=username, email=email)
            if response:
                return response
            return json.dumps({'status': 'success'})

        elif step == "step-3":
            month = request.form.get('month')
            day = request.form.get('day')
            year = request.form.get('year')
            gender = request.form.get('gender')

            username = request.form.get("username")
            email = request.form.get("email")

            password = request.form.get("password")
            repeat_password = request.form.get("repeat-password")

            response = funcs.verify_traits(month=month, day=day, year=year, gender=gender)
            if response:
                return response
            response = funcs.verify_identifiers(username=username, email=email)
            if response:
                return response
            response = funcs.verify_secret(password=password, repeat_password=repeat_password)
            if response:
                return response

            user = models.User(username=username, email=email, gender=gender)
            user.set_password(password)
            user.set_birthdate(date(month=int(month), day=int(day), year=int(year)))
            try:
                funcs.send_auth_email(user=user, sender=current_app.config['ADMINS'][0])
            except smtplib.SMTPException as e:
                return json.dumps({'status': 'Email not sent', 'msg': 'Error: Email Not Sent', 'display': "flash"})
            db.session.add(user)
            db.session.commit()
            return json.dumps({'status': 'success'})

        elif step == "finally":

            username = request.form.get("username")
            password = request.form.get("password")

            user = models.User.query.filter_by(username=username).first()
            if not user:
                return json.dumps({'status': 'error'})
            if user.token_is_expired:
                return token_is_expired_error(token=user.token)
            try:
                funcs.send_auth_email(user=user, sender=current_app.config['ADMINS'][0])
            except smtplib.SMTPException as e:
                return json.dumps({'status': 'Email not sent', 'msg': 'Error: Email Not Sent', 'display': "flash"})
            return json.dumps({'status': 'success'})

        return json.dumps({'status': 'error'})

    return render_template("auth/register.html", background=True, size="medium", navbar=True)


@bp.route("/login/", methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("index.index"))

    if request.method == 'POST':
        username = request.form.get("username")
        password = request.form.get("password")
        print(password)

        if not username:
            return json.dumps({'status': 'Username must be filled in', 'box_ids': ['username']})

        if not password:
            return json.dumps({'status': 'Password must be filled in', 'box_ids': ['password']})

        user = models.User.query.filter_by(username=username).first()

        if user is None or not user.check_password(password) or not user.is_activated:
            print(user)
            print(password)
            print(user.is_activated)
            return json.dumps({'status': 'Incorrect username or password', 'box_ids': ['username', 'password']})

        login_user(user, remember=True)
        return json.dumps({'status': 'success'})
    return render_template("auth/login.html", background=True, size="medium", navbar=True)


@ bp.route("/logout/", methods=['GET', 'POST'])
@ login_required
def logout():
    if request.method == 'POST':
        logout_user()
        return json.dumps({'status': 'success'})
    return render_template("auth/logout.html", size="medium")


@bp.route('/activate/<token>/', methods=['GET', 'POST'])
def activate(token):
    print("wawawawaw")
    if current_user.is_authenticated:
        return redirect(url_for('index.index'))
    user = models.User.check_token(token=token)
    print(user)
    if not user:
        return token_is_expired_error(token=token)
    user.is_activated = True
    user.revoke_token()
    db.session.commit()
    login_user(user, remember=True)
    return redirect(url_for('index.index'))
