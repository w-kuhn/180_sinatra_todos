require 'pg'

class DatabasePersistance
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    statement = "SELECT * FROM lists"
    result = query(statement)

    result.map do |tuple|
      {id: tuple["id"].to_i, name: tuple["name"], todos: populate_todos(tuple["id"])}
    end
  end

  def find_list(id)
    statement = "SELECT * FROM lists WHERE id = $1"
    result = query(statement, id)

    tuple = result.first
    list_id = tuple["id"].to_i
    todos = populate_todos(list_id)
    {id: tuple["id"], name: tuple["name"], todos: todos}
  end
  
  def create_new_list(list_name)
    statement = "INSERT INTO lists (name) VALUES ($1);"

    query(statement, list_name)
  end

  def delete_list(list_id)
    delete_list_todos = "DELETE FROM todos WHERE list_id = $1;"
    query(delete_list_todos, list_id)

    delete_list = "DELETE FROM lists WHERE id = $1;"
    query(delete_list, list_id)
  end

  def update_list_name(list_id, list_name)
    statement = "UPDATE lists SET name = $1 WHERE id = $2"
    query(statement, list_name, list_id)
  end

  def add_new_todo(list_id, todo_name)
    statement = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(statement, todo_name, list_id)
  end

  def delete_todo(list_id, todo_id)
    statement = "DELETE FROM todos WHERE id = $2 AND list_id = $1;"
    query(statement, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    statement = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query(statement, new_status, todo_id, list_id)
  end

  def mark_all_todos_complete(list_id)
    statement = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(statement, list_id)
  end

  def has_list?(list_name)
    all_lists.any? { |list| list[:name] == list_name }
  end

  private

  def populate_todos(list_id)
    statement = "SELECT * FROM todos WHERE list_id = $1;"
    result = @db.exec_params(statement, [list_id])

    result.map do |tuple|
      {id: tuple["id"], name: tuple["name"], completed: tuple["completed"] == "t", list_id: tuple["list_id"]}
    end
  end
end