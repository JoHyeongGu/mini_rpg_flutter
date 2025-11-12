from flask import Flask, jsonify, session, request, g
import pymysql, random

app = Flask(__name__)
app.secret_key = "game_database_modeling_class"

db_config = {
    "host": "127.0.0.1",
    "user": "minirpg",
    "password": "minirpg",
    "database": "minirpg",
    "cursorclass": pymysql.cursors.DictCursor,
}


def get_db():
    if "db" not in g:
        g.db = pymysql.connect(**db_config)
    return g.db


@app.teardown_appcontext
def close_db(exception):
    db = g.pop("db", None)
    if db is not None:
        db.close()


# region User
# Create a new user
@app.route("/register", methods=["POST"])
def create_user():
    data = request.get_json()
    user_id = data.get("user_id")
    email = data.get("email")
    password = data.get("password")
    if not data or user_id is None or not email or not password:
        return jsonify({"message": "missing input parameters"}), 400
    conn = get_db()
    query = "INSERT INTO user (user_id, password, email) values (%s, %s, %s)"
    data_set = (data["user_id"], data["password"], data["email"])
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return (
            jsonify({"message": "complete user register", "id": data["user_id"]}),
            201,
        )
    except Exception as e:
        conn.rollback()
        return jsonify({"message": "failed to register", "error": str(e)}), 500


@app.route("/login", methods=["POST"])
def login():
    if session.get("login") is not None:
        return jsonify({"message": "already logged in user"}), 400

    data = request.get_json()
    user_id = data.get("user_id")
    password = data.get("password")

    if not password or user_id is None:
        return jsonify({"message": "invalid login arguments"}), 400

    conn = get_db()

    query = "SELECT user_id, password, last_accessed_char FROM user WHERE user_id = %s OR email = %s"
    data_set = (user_id, user_id)

    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            row = cursor.fetchone()

        if row is None:
            return jsonify({"message": "cannot find user"}), 404
        if row["password"] != password:
            return jsonify({"message": "Invalid Password"}), 404

        session["login"] = row["user_id"]
        last_char = row.get("last_accessed_char")
        return jsonify({"message": "complete to login", "last_char": last_char}), 200

    except Exception as e:
        return jsonify({"message": "failed to login", "error": str(e)}), 500


@app.route("/login/char/<int:char_id>", methods=["PATCH"])
def update_last_accessed(char_id):
    user_id = session.get("login")
    if user_id is None or char_id is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "UPDATE user SET last_accessed_at = NOW(), last_accessed_char = %s WHERE user_id = %s"
    data_set = (char_id, user_id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return jsonify({"message": "complete to update accessed"}), 200
    except Exception as e:
        conn.rollback()
        return (
            jsonify({"message": "failed to update last accessed", "error": str(e)}),
            500,
        )


# Clear Login Session
@app.route("/logout", methods=["GET"])
def logout():
    session.clear()
    return jsonify({"message": "complete to logout"}), 200


# Get a user data
@app.route("/user", methods=["GET"])
@app.route("/user/<string:user_id>", methods=["GET"])
def get_user_data(user_id=None):
    if user_id is None:
        user_id = session.get("login")
        if user_id is None:
            return jsonify({"message": "No input data"}), 400
    conn = get_db()
    query = "SELECT * FROM user WHERE user_id = %s"
    data_set = (user_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            data = cursor.fetchone()
        return jsonify({"data": data}), 200
    except Exception as e:
        return jsonify({"message": "failed to find user", "error": str(e)}), 500


# Get All userId only for logged in user
@app.route("/users", methods=["GET"])
def get_all_user_ids():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "SELECT user_id FROM user"
    try:
        with conn.cursor() as cursor:
            cursor.execute(query)
            users = cursor.fetchall()
        return jsonify({"data": [user["user_id"] for user in users]}), 200
    except Exception as e:
        return (
            jsonify({"message": "failed to get all users", "error": str(e)}),
            500,
        )  # endregion


# region Character list
# Get logged in User's all characters
@app.route("/characters", methods=["GET"])
def get_all_characters():
    user_id = session.get("login")
    if user_id is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    char_column = [
        "char_id",
        "nickname",
        "gender",
        "level",
        "coin",
        "exp",
        "created_at",
    ]
    class_column = ["name as class_name", "color as class_color"]
    query = (
        "SELECT "
        + ", ".join([f"c.{c}" for c in char_column] + [f"cl.{c}" for c in class_column])
        + " FROM character_list c"
        + " JOIN character_class cl ON c.class_id = cl.class_id"
        + " WHERE c.user_id = %s AND c.deleted_at IS NULL"
    )
    data_set = (user_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            characters = cursor.fetchall()
        return jsonify({"data": characters}), 200
    except Exception as e:
        return jsonify({"message": "failed to get characters", "error": str(e)}), 500


# Get a Character's Detail Info
@app.route("/character/detail/<int:char_id>", methods=["GET"])
def get_character(char_id):
    user_id = session.get("login")
    if user_id is None or char_id is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    char_column = [
        "char_id",
        "class_id",
        "nickname",
        "gender",
        "level",
        "coin",
        "exp",
        "hp",
    ]
    stat_column = ["hp as max_hp", "def", "atk", "speed", "atk_range", "atk_speed"]
    query = (
        "SELECT "
        + ", ".join(
            [f"c.{c}" for c in char_column] + [f"st.{st}" for st in stat_column]
        )
        + " FROM character_list c"
        + " JOIN stat st ON c.stat_id = st.stat_id"
        + " WHERE c.char_id = %s AND c.user_id = %s AND c.deleted_at IS NULL"
    )
    data_set = (char_id, user_id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            character = cursor.fetchone()
        if not character:
            return jsonify({"data": None}), 404
        else:
            return jsonify({"data": character}), 200
    except Exception as e:
        return jsonify({"message": "failed to get a character", "error": str(e)}), 500


# Create a new character
@app.route("/character/create", methods=["POST"])
def create_character():
    user_id = session.get("login")
    if user_id is None:
        return jsonify({"message": "Denied Request"}), 401
    data = request.get_json()
    data["user_id"] = user_id
    class_id = data.get("class_id")
    nickname = data.get("nickname")
    if not data or not class_id or not nickname:
        return jsonify({"message": "missing input parameters"}), 400
    conn = get_db()
    stat_req, hp = create_stat_with_class_id(conn, class_id)
    if "error" in stat_req:
        return (
            jsonify(
                {"message": stat_req.get("message"), "error": stat_req.get("error")}
            ),
            500,
        )
    data["stat_id"] = stat_req["id"]
    result = force_delete_character_by_nickname(conn, nickname)
    if result.get("error") is not None:
        return jsonify({"message": f"{nickname} is already exist"}), 400
    query = "INSERT INTO character_list (user_id, class_id, nickname, gender, stat_id, hp) values (%s, %s, %s, %s, %s, %s)"
    data_set = (
        data["user_id"],
        data["class_id"],
        data["nickname"],
        data.get("gender"),
        data.get("stat_id"),
        hp,
    )
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            inserted_id = cursor.lastrowid
        conn.commit()
        return (
            jsonify({"message": "complete to create character", "id": inserted_id}),
            201,
        )
    except Exception as e:
        conn.rollback()
        return jsonify({"message": "failed to create character", "error": str(e)}), 500


# Delete a character
@app.route("/character/<int:char_id>", methods=["DELETE"])
def delete_character(char_id):
    user_id = session.get("login")
    if user_id is None or char_id is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "UPDATE character_list SET deleted_at = NOW() WHERE char_id = %s AND user_id = %s"
    data_set = (char_id, user_id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return jsonify({"message": "complete to delete character"}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"message": "failed to delete character", "error": str(e)}), 500


def force_delete_character_by_nickname(conn, nickname):
    query = "DELETE FROM character_list WHERE nickname = %s AND deleted_at IS NOT NULL"
    data_set = (nickname,)
    print(query, nickname)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return {"message": "complete to force delete character"}
    except Exception as e:
        conn.rollback()
        return {"message": "failed to force delete character", "error": str(e)}


# save user data
@app.route("/character/update", methods=["PATCH"])
def update_character_data():
    user_id = session.get("login")
    if user_id is None:
        return jsonify({"message": "Denied Request"}), 401
    data = request.get_json()
    char_id = data.get("char_id")
    level = data.get("level")
    coin = data.get("coin")
    exp = data.get("exp")
    hp = data.get("hp")
    if (
        not data
        or char_id is None
        or level is None
        or coin is None
        or exp is None
        or hp is None
    ):
        return jsonify({"message": "missing input parameters"}), 400
    conn = get_db()
    query = "UPDATE character_list SET level = %s, coin = %s, exp = %s, hp = %s WHERE char_id = %s AND user_id = %s"
    data_set = (level, coin, exp, hp, char_id, user_id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return jsonify({"message": "complete to save char data"}), 200
    except Exception as e:
        conn.rollback()
        return (
            jsonify({"message": "failed to save char data", "error": str(e)}),
            500,
        )  # endregion


# region Character Class
# Get a specific class
@app.route("/class/<int:class_id>", methods=["GET"])
def get_specific_class(class_id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    result = select_one_class(conn, class_id)
    if result.get("data") != None:
        return jsonify(result), 200
    else:
        return jsonify(result), 500


def select_one_class(conn, class_id, column="*"):
    query = f"SELECT {column} FROM character_class WHERE class_id = %s"
    data_set = (class_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            data = cursor.fetchone()
            return {"data": data, "message": "complete to select class"}
    except Exception as e:
        return {"message": "failed to select a class", "error": str(e)}


@app.route("/class/all", methods=["GET"])
def get_all_class():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    # if patent class is locked, all children will be locked too.
    query = (
        "SELECT c.class_id, c.include_class, c.name, c.color FROM character_class AS c"
        + " LEFT JOIN character_class AS parent"
        + " ON c.include_class = parent.class_id"
        + " WHERE (c.include_class IS NULL AND c.open_flag = TRUE)"
        + " OR (c.include_class IS NOT NULL AND c.open_flag = TRUE"
        + " AND parent.open_flag = TRUE)"
    )
    try:
        with conn.cursor() as cursor:
            cursor.execute(query)
            classes = cursor.fetchall()
        data = {}
        for c in classes:
            if c.get("include_class") == None:
                data[c["class_id"]] = {
                    "name": c["name"],
                    "color": c["color"],
                    "child": [],
                }
        for c in classes:
            if c.get("include_class") != None:
                data[c["include_class"]]["child"].append(
                    {"id": c["class_id"], "name": c["name"], "color": c["color"]}
                )

        return jsonify(data), 200
    except Exception as e:
        return (
            jsonify({"message": "failed to get all classes", "error": str(e)}),
            500,
        )  # endregion


# region Stat
# Get a specific stat
@app.route("/stat/<int:stat_id>", methods=["GET"])
def get_stat(stat_id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    result = select_stat(conn, stat_id)
    if result.get("data") != None:
        return jsonify(result), 200
    else:
        return jsonify(result), 500


def select_stat(conn, stat_id, column="*"):
    query = f"SELECT {column} FROM stat WHERE stat_id = %s"
    data_set = (stat_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            data = cursor.fetchone()
            return {"data": data, "message": "complete to select stat"}
    except Exception as e:
        return {"message": "failed to select stat", "error": str(e)}


def create_stat_with_class_id(conn, class_id, level=10):
    query = f"SELECT stat_id FROM class_stat WHERE class_id = %s AND level = %s"
    data_set = (class_id, level)
    with conn.cursor() as cursor:
        cursor.execute(query, data_set)
        data = cursor.fetchone()
    stat_id = data["stat_id"]
    stat_data = select_stat(conn, stat_id).get("data", {})
    return insert_stat(conn, stat_data), stat_data["hp"]


# Create a new Stat
@app.route("/stat", methods=["POST"])
def create_stat():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    data = request.get_json()
    conn = get_db()
    result = insert_stat(conn, data)
    if "error" in result:
        return jsonify(result), 500
    return jsonify(result), 201


def insert_stat(conn, data):
    query = "INSERT INTO stat (hp, atk, def, speed, atk_range, atk_speed) values (%s, %s, %s, %s, %s, %s)"
    data_set = (
        data.get("hp"),
        data.get("atk"),
        data.get("def"),
        data.get("speed"),
        data.get("atk_range"),
        data.get("atk_speed"),
    )
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            inserted_id = cursor.lastrowid
        conn.commit()
        return {"message": "complete to create stat", "id": inserted_id}
    except Exception as e:
        conn.rollback()
        return {"message": "failed to create stat", "error": str(e)}  # endregion


# region Skill
@app.route("/class/skills/<int:class_id>", methods=["GET"])
def get_skills_for_class(class_id):
    user_id = session.get("login")
    if user_id is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    skill_column = [
        "level",
        "name",
        "description",
        "img",
        "cooltime",
        "target",
        "target_count",
        "type",
    ]
    stat_column = ["*"]
    query = (
        "SELECT "
        + ", ".join(
            [f"s.{s}" for s in skill_column] + [f"st.{st}" for st in stat_column]
        )
        + " FROM skill s"
        + " JOIN stat st ON s.stat_id = st.stat_id"
        + " WHERE s.class_id = %s"
    )
    data_set = (class_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            skills = cursor.fetchall()
        return jsonify({"data": skills}), 200
    except Exception as e:
        return (
            jsonify({"message": "failed to get skills", "error": str(e)}),
            500,
        )  # endregion


# region Max Exp
@app.route("/exp/<int:class_id>", methods=["GET"])
def get_max_exp_for_class(class_id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "SELECT level, exp FROM max_exp WHERE class_id = %s"
    data_set = (class_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            exps = cursor.fetchall()
        return jsonify(exps), 200
    except Exception as e:
        return (
            jsonify({"message": "failed to get Max EXP", "error": str(e)}),
            500,
        )  # endregion


# region World
@app.route("/world/<string:et>/<int:id>", methods=["GET"])
def get_specific_world_data(et, id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "SELECT * FROM world WHERE entity_type = %s AND entity_id = %s AND spawn_flag = true"
    data_set = (et, id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            data = cursor.fetchone()
        return jsonify(data), 200
    except Exception as e:
        return jsonify({"message": "failed to get World data", "error": str(e)}), 500


@app.route("/world/all/<int:id>", methods=["GET"])
def get_world_data(id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "SELECT * FROM world JOIN npc n ON entity_id = n.npc_id WHERE ((entity_type = 'player' AND entity_id = %s) OR entity_type = 'npc') AND spawn_flag = true"
    data_set = (id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            datas = cursor.fetchall()
        result = {"npc": [], "player": None}
        for d in datas:
            if d["entity_type"] == "npc":
                result["npc"].append(d)
            else:
                result["player"] = d
                del result["player"]["npc_id"]
                del result["player"]["name"]
                del result["player"]["career"]
                del result["player"]["entity_img"]
                del result["player"]["detail_img"]
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"message": "failed to get World Datas", "error": str(e)}), 500


@app.route("/world/player_add", methods=["POST"])
def insert_player_world_data():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    data = request.get_json()
    char_id = data.get("id")
    x_pos = data.get("x")
    y_pos = data.get("y")
    if not data or char_id is None or x_pos is None or y_pos is None:
        return jsonify({"message": "missing input parameters"}), 400
    conn = get_db()
    query = "INSERT INTO world (entity_id, x_pos, y_pos) values (%s, %s, %s)"
    data_set = (char_id, x_pos, y_pos)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return (
            jsonify({"message": "complete to add player position"}),
            201,
        )
    except Exception as e:
        conn.rollback()
        return (
            jsonify({"message": "failed to add player position", "error": str(e)}),
            500,
        )


@app.route("/world/update", methods=["PATCH"])
def update_user_position():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    data = request.get_json()
    print(data)
    char_id = data.get("id")
    x_pos = data.get("x")
    y_pos = data.get("y")
    if not data or char_id is None or x_pos is None or y_pos is None:
        return jsonify({"message": "missing input parameters"}), 400
    conn = get_db()
    query = "UPDATE world SET x_pos = %s, y_pos = %s WHERE entity_type = 'player' AND entity_id = %s"
    data_set = (
        x_pos,
        y_pos,
        char_id,
    )
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return jsonify({"message": "complete to update position"}), 200
    except Exception as e:
        conn.rollback()
        return (
            jsonify({"message": "failed to update position", "error": str(e)}),
            500,
        )  # endregion


# region Item & Shop
@app.route("/inventory/<int:char_id>", methods=["GET"])
def get_inventory_items(char_id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = (
        "SELECT it.item_id, it.type, it.name, it.description, it.img, i.count, i.equip_flag "
        + "FROM inventory i JOIN item it ON i.item_id = it.item_id "
        + "WHERE i.char_id = %s"
    )
    data_set = (char_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            data = cursor.fetchall()
        return jsonify(data), 200
    except Exception as e:
        return jsonify({"message": "failed to get shop data", "error": str(e)}), 500


@app.route("/shop", methods=["GET"])
def get_all_shop_data():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = (
        "SELECT i.item_id, i.type, i.name, i.description, i.img, s.price "
        + "FROM shop s JOIN item i ON s.item_id = i.item_id"
    )
    try:
        with conn.cursor() as cursor:
            cursor.execute(query)
            data = cursor.fetchall()
        return jsonify(data), 200
    except Exception as e:
        return jsonify({"message": "failed to get shop data", "error": str(e)}), 500


# Buy Item
@app.route("/buy", methods=["POST"])
def insert_inventory():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401

    data = request.get_json()
    char_id = data.get("char_id")
    item_id = data.get("item_id")
    count = data.get("count")

    if not data or char_id is None or item_id is None:
        return jsonify({"message": "missing input parameters"}), 400

    conn = get_db()

    already_data = get_already_item(conn, char_id, item_id)
    if already_data is not None:
        already_count = already_data.get("count")
        if already_count is not None and already_count > 0:
            add_already_item(conn, char_id, item_id, already_count + 1)
            return jsonify({"message": "complete Buy Item"}), 201
    query = "INSERT INTO inventory (char_id, item_id, count) values (%s, %s, %s)"
    data_set = (char_id, item_id, count)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return jsonify({"message": "complete Buy Item"}), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"message": "failed to buy Item", "error": str(e)}), 500


def get_already_item(conn, char_id, item_id):
    query = "SELECT count FROM inventory WHERE char_id = %s AND item_id = %s"
    data_set = (char_id, item_id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            data = cursor.fetchone()
        return data
    except Exception as e:
        return {"message": "failed to get inven item", "error": str(e)}


def add_already_item(conn, char_id, item_id, count):
    query = "UPDATE inventory SET count = %s WHERE char_id = %s AND item_id = %s"
    data_set = (count, char_id, item_id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return {"message": "complete to update count"}
    except Exception as e:
        conn.rollback()
        return {"message": "failed to update count", "error": str(e)}  # endregion


# region Quest
@app.route("/quest/<int:npc_id>", methods=["GET"])
def get_random_quest(npc_id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "SELECT quest_id, npc_talk, need_count, reward_coin, reward_exp FROM quest WHERE npc_id = %s"
    data_set = (npc_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            datas = cursor.fetchall()
        return jsonify(random.choice(datas)), 200
    except Exception as e:
        return jsonify({"message": "failed to get quest", "error": str(e)}), 500


@app.route("/quest/accept", methods=["POST"])
def accept_quest():
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    data = request.get_json()
    char_id = data.get("char_id")
    quest_id = data.get("quest_id")
    if char_id is None or quest_id is None:
        return jsonify({"message": "missing input parameters"}), 400
    conn = get_db()
    query = "INSERT INTO accept_quest (char_id, quest_id) values (%s, %s)"
    data_set = (char_id, quest_id)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
        conn.commit()
        return (
            jsonify({"message": "complete to accept quest"}),
            201,
        )
    except Exception as e:
        conn.rollback()
        return jsonify({"message": "failed to accept quest", "error": str(e)}), 500


@app.route("/quest/accept/all/<int:char_id>", methods=["GET"])
def get_all_accepted_quests(char_id):
    if session.get("login") is None:
        return jsonify({"message": "Denied Request"}), 401
    conn = get_db()
    query = "SELECT * FROM accept_quest aq JOIN quest q ON aq.quest_id = q.quest_id WHERE char_id = %s"
    data_set = (char_id,)
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, data_set)
            datas = cursor.fetchall()
        return jsonify(datas), 200
    except Exception as e:
        return (
            jsonify({"message": "failed to get accepte quests", "error": str(e)}),
            500,
        )


# endregion
if __name__ == "__main__":
    app.run(debug=True)
