# Runs inside the dedicated Redmine demo after the official image migrates SQLite.
root = '/homework'
identifier = 'voltmarket'
wiki_text = File.read(File.join(__dir__, 'wiki.md'), encoding: 'UTF-8')
welcome = '[Задачи команды](/projects/voltmarket/issues?set_filter=1&status_id=*) · [Процессы бронирования](/projects/voltmarket/wiki)'
if (existing = Project.find_by(identifier: identifier))
  wiki = existing.wiki
  page = wiki.find_page('Процессы') || wiki.find_page('Wiki')
  if page && page.content.text.include?('## Что показать преподавателю')
    author = User.active.where(admin: true).order(:id).first!
    Project.transaction do
      User.current = author
      page.update!(title: 'Процессы')
      page.content.update!(author: author, text: wiki_text)
      wiki.update!(start_page: 'Процессы')
      existing.update!(description: 'Учёт бронирования, продаж и освобождения резервов в магазине электроники.')
    end
  end
  Setting.welcome_text = welcome if Setting.welcome_text.include?('вики защиты')
  exit
end

Project.transaction do
  raise 'Expected an empty demo instance' if Project.exists?
  Redmine::DefaultData::Loader.load('ru') if Redmine::DefaultData::Loader.no_data?
  Setting.default_language = 'ru'
  Setting.text_formatting = 'common_mark'
  Setting.self_registration = '0'
  Setting.login_required = '0'
  Setting.app_title = 'ВольтМаркет · Redmine'
  Setting.welcome_text = welcome
  admin = User.active.where(admin: true).order(:id).first!
  admin.password = admin.password_confirmation = SecureRandom.hex(32)
  admin.save!
  User.current = admin
  project = Project.create!(identifier: identifier, name: 'ВольтМаркет',
    description: 'Бронирование, продажа и автоснятие просроченных резервов в магазине электроники.', is_public: true)
  project.enabled_module_names = %w[issue_tracking wiki]
  tracker = Tracker.sorted.first!
  project.trackers = [tracker]
  wiki = project.wiki || project.create_wiki!(start_page: 'Wiki')
  status = IssueStatus.where(is_closed: true).order(:position).first!
  tasks = [
    ['Разобрать СППР и блокировку остатков', 'При проведении брони документ блокирует остатки и резерв по товару и затем проверяет свободное количество. В отчёте на с. 1 описаны требование, роль продавца, два регистра и критерий приёмки.', ['Демонстрация/redmine/ВольтМаркет — процессы и автотесты.pdf']],
    ['Описать бронь и автоснятие в BPMN', 'Две страницы схемы показывают ручной и автоматический пути. Схемы доступны прямо в вики и во вложенном редактируемом файле.', ['Процессы.drawio']],
    ['Проверить передачу и частичное снятие резерва', 'ВМ-01 проверяет, что после отмены первой брони ноутбук можно забронировать для второго покупателя. ВМ-02 проверяет автоснятие одной оставшейся единицы. Ниже приложены обработка и протокол выполнения в 1С.', ['tests/ПроверкиБрони.epf','tests/ПроверкиБрони.bsl','tests/Протокол.txt']]
  ]
  attach = lambda do |owner, path|
    File.open(File.join(root, path), 'rb') do |io|
      a = Attachment.new(container: owner, author: admin)
      a.file = io
      a.filename = File.basename(path)
      a.content_type = Redmine::MimeType.of(a.filename)
      a.save!
      a
    end
  end
  tasks.each do |subject, description, files|
    issue = Issue.create!(project: project, tracker: tracker, author: admin, subject: subject,
      description: description, due_date: Date.new(2026,11,19), status: status, done_ratio: 100)
    files.each { |path| attach.call(issue, path) }
  end
  wiki.update!(start_page: 'Процессы')
  page = wiki.pages.build(title: 'Процессы')
  page.content = WikiContent.new(author: admin, text: wiki_text)
  page.save!
  %w[reservation.png expiry.png].each { |name| attach.call(page, "Демонстрация/redmine/#{name}") }
end
