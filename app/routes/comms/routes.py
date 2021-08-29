from flask import redirect, url_for, render_template, abort, current_app
from flask import request as flask_request
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import json
from app import db, models
from app.routes.comms import bp
import app.routes.comms.funcs as funcs
from urllib.parse import urlencode


@login_required
@ bp.route("/messages/", methods=["GET", "POST"])
def messages():
    convos = current_user.convos
    return render_template("comms/messages/messages.html", navbar=True, background=True, size="medium", models=models, convos = convos)

@login_required
@ bp.route("/message/<username>/", methods=["GET", "POST"])
def message(username):
    user = models.User.query.filter_by(username=username).first_or_404()
    # Get the dialogue between current_user and user if it exists
    convo = models.Convo.get_dialogue(user, current_user)
    if flask_request.method == "POST":
        text = flask_request.form.get("text")
        if not text:
            return json.dumps({'status': 'error'})
        if convo:
            if convo.activated:
                new_msg = models.Message(text=text, sender=current_user)
                convo.messages.append(new_msg)
                db.session.commit()
                return json.dumps({'status': 'success'})
            else:
                if convo.messages.has(sender=user):
                    convo.activated = True
                    new_msg = models.Message(text=text, sender=current_user)
                    convo.messages.append(new_msg)
                    db.session.commit()
                    return json.dumps({'status': 'success'})

                else:
                    new_msg = models.Message(text=text, sender=current_user)
                    convo.messages.append(new_msg)
                    db.session.commit()
                    return json.dumps({'status': 'success'})

        elif user in current_user.allies:
            print("allies")
            convo = models.Convo(activated=True)
            convo.members.append(current_user)
            convo.members.append(user)
            new_msg = models.Message(text=text, sender=current_user)
            convo.messages.append(new_msg)
            db.session.commit()
            return json.dumps({'status': 'success'})
        else:
            convo = models.Convo()
            convo.members.append(current_user)
            convo.members.append(user)
            db.session.commit()
            return json.dumps({'status': 'success'})
    return render_template("comms/messages/message.html", user=user, convo=convo, navbar=True, background=True, size="medium", models=models)


@ bp.route("/get/messages/<username>/", methods=["POST"])
def get_messages(username):
    user = models.User.query.filter_by(username=username).first_or_404()
    # Get the dialogue between current_user and user if it exists
    convo = models.Convo.get_dialogue(user, current_user)
    if flask_request.method == 'POST':
        if convo:
            latest_id = flask_request.form.get("latest_id")
            latest_messages = convo.get_latest_messages_by_latest_id(latest_id)
            print(latest_messages)
            formatted_messages = [msg.get_json_info() for msg in latest_messages]
            print(formatted_messages)
            return json.dumps({'status': 'success', 'latest_messages': formatted_messages})
        return json.dumps({'status': 'error'})

@login_required
@ bp.route("/convo/<id>/", methods=["GET", "POST"])
def conversation(id):
    convo = models.Convo.query.filter_by(id=id).first_or_404()
    return render_template("comms/message.html", convo=convo, navbar=True, background=True, size="medium", models=models)

@ bp.route("/feedback/", methods=["GET", "POST"])
def feedback():

    if flask_request.method == 'POST':

        search = flask_request.form.get("search")
        by = flask_request.form.get("by")
        page = flask_request.form.get("page", 1, type=int)
        
        params = {}
        if search:
            params.update({'search':search})

        if by:
            params.update({'by':by})

        if page:
            params.update({'page':page})


        path =  "/feedback?"+urlencode(params)
        feedback, page_count = models.Feedback.search_by(search,by).custom_paginate(page=page, per_page=5, return_page_count=True)
        page = min(page_count,max(0,page))
        return json.dumps({'status': 'success', 'path': path, 'feedback':[{"id":fb.id,"title":str(fb.title), "content":str(fb.content),"upvotes":fb.upvotes.count(),"downvotes":fb.downvotes.count(), "is_upvoted":fb.is_upvoted(current_user), "is_downvoted":fb.is_downvoted(current_user)} for fb in feedback], 'page':page, 'page_count':page_count})

    if flask_request.method == 'GET':
        # Get q strings to provide search from url
        q_search = flask_request.args.get('search')
        q_by = flask_request.args.get('by', 'top', type=str)
        q_page = flask_request.args.get('page', 1, type=int)
        feedback, page_count = models.Feedback.search_by(q_search,q_by).custom_paginate(page=q_page, per_page=5, return_page_count=True)
        page = min(page_count,max(0,q_page))
        return render_template("comms/feedback/feedback.html", feedback=feedback, navbar=True, background=True, size="medium", models=models, enumerate=enumerate, funcs=funcs, page_count=page_count,page=page,by=q_by,search=q_search, max=max,min=min, url=flask_request.url)




@ bp.route("/feedback/<fb_id>/", methods=["GET", "POST"])
def feedback_post(fb_id):
    print(fb_id)
    post = models.Feedback.query.filter_by(id=fb_id).first_or_404()
    if flask_request.method == 'POST':
        return json.dumps({'status': 'success', "post":{"id":post.id, "title":str(post.title), "content":str(post.content),"upvotes":post.upvotes.count(),"downvotes":post.downvotes.count(), "is_upvoted":post.is_upvoted(current_user), "is_downvoted":post.is_downvoted(current_user)}})
    return render_template("comms/feedback/feedback.html", post=post, navbar=True, background=True, size="medium", models=models, url=flask_request.url, max=max,min=min)


@login_required
@ bp.route("/feedback/submit/", methods=["GET", "POST"])
def submit_feedback():
    if flask_request.method == 'POST':
        action = flask_request.form.get("action")
        title = flask_request.form.get("title")
        text = flask_request.form.get("text")
        print(title)
        print(text)

        if action == "submit":
            if title:
                fb = models.Feedback(title=title,content=text,author=current_user, public=True)
                db.session.add(fb)
                db.session.commit()
                return json.dumps({'status': 'success', 'id':fb.id})
            return json.dumps({'status': 'error'})

        if action == "save":
            if title or text:
                fb = models.Feedback(title=title,content=text,author=current_user, public=False)
                db.session.add(fb)
                db.session.commit()
                return json.dumps({'status': 'success'})
            return json.dumps({'status': 'error'})

    return render_template("comms/feedback/submit.html", navbar=True, background=True, size="medium", models=models)

@ bp.route("/feedback/vote/", methods=["POST"])
def vote_feedback():
    if flask_request.method == 'POST':
        fb_id = flask_request.form.get("fb_id")
        action = flask_request.form.get("action")
        fb = models.Feedback.query.get(fb_id)
        print(fb_id)
        print(action)
        print(fb)
        if action == "upvote":
            fb.upvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif action == "downvote":
            fb.downvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif action == "unupvote":
            fb.unupvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif action == "undownvote":
            fb.undownvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        return json.dumps({'status': 'error'})

@ bp.route("/post/vote/", methods=["POST"])
def vote_post():
    if flask_request.method == 'POST':
        post_id = flask_request.form.get("post_id")
        action = flask_request.form.get("action")
        post = models.Post.query.get(post_id)
        print(post_id)
        print(action)
        print(post)
        if action == "upvote":
            post.upvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif action == "downvote":
            post.downvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif action == "unupvote":
            post.unupvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif action == "undownvote":
            post.undownvote(voter=current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        return json.dumps({'status': 'error'})


@ bp.route("/wall/", methods=["GET", "POST"])
def wall():
    #posts = current_user
    return render_template("comms/wall/wall.html", navbar=True, background=True, size="medium", models=models)
