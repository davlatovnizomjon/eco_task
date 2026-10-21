import 'package:eco_task/domain/common/enums/expense_kind.dart';
import 'package:eco_task/domain/common/enums/expense_status.dart';
import 'package:eco_task/domain/common/enums/log_kind.dart';
import 'package:eco_task/domain/common/enums/notification_kind.dart';
import 'package:eco_task/domain/common/enums/request_kind.dart';
import 'package:eco_task/domain/common/enums/request_status.dart';
import 'package:eco_task/domain/common/enums/task_priority.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/comment_model.dart';
import 'package:eco_task/infrastructure/dto/models/expense_model.dart';
import 'package:eco_task/infrastructure/dto/models/log_entry.dart';
import 'package:eco_task/infrastructure/dto/models/notification_model.dart';
import 'package:eco_task/infrastructure/dto/models/request_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_assignee.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';

/// Deterministic demo data the mock backend starts with. Dates are relative
/// to "now" so the screens never look stale. The data is written as typed
/// models; `MockStore` serializes them like the live API would.
abstract final class MockSeed {
  /// Moment [days] from today at [hour]:[minute].
  static DateTime at(int days, [int hour = 9, int minute = 0]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days, hour, minute);
  }

  /// Moment [minutes] before now.
  static DateTime ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes));

  /// Team of the sales and delivery staff.
  static const sales = 'Sotuv va yetkazish';

  /// Team of the greenhouse staff.
  static const greenhouse = 'Issiqxona';

  /// Every seeded account; the id doubles as the login and the password is `1234`.
  static const users = [
    AppUser(
      id: 'jamshid',
      name: 'Jamshid Aliyev',
      role: UserRole.owner,
      phone: '+998901234567',
      team: 'Eco Ko‘chatzor',
      color: 4,
    ),
    AppUser(
      id: 'malika',
      name: 'Malika Tosheva',
      role: UserRole.assistant,
      phone: '+998912223344',
      team: sales,
      color: 5,
    ),
    AppUser(id: 'boris', name: 'Boris Ivanov', role: UserRole.worker, phone: '+998901112233', team: sales, color: 0),
    AppUser(
      id: 'nizomjon',
      name: 'Nizomjon Karimov',
      role: UserRole.worker,
      phone: '+998901112234',
      team: sales,
      color: 1,
    ),
    AppUser(
      id: 'azizbek',
      name: 'Azizbek Rahimov',
      role: UserRole.worker,
      phone: '+998901112235',
      team: sales,
      color: 2,
    ),
    AppUser(
      id: 'dilshod',
      name: 'Dilshod Yusupov',
      role: UserRole.worker,
      phone: '+998901112236',
      team: greenhouse,
      color: 3,
    ),
    AppUser(
      id: 'gulnora',
      name: 'Gulnora Saidova',
      role: UserRole.client,
      phone: '+998975551234',
      team: 'Yunusobod',
      color: 3,
    ),
    AppUser(
      id: 'otabek',
      name: 'Otabek Toshmatov',
      role: UserRole.client,
      phone: '+998975551235',
      team: 'Chilonzor',
      color: 1,
    ),
    AppUser(
      id: 'gulzor',
      name: '«Gulzor» kafe',
      role: UserRole.client,
      phone: '+998975551236',
      team: 'Mirobod',
      color: 2,
    ),
    AppUser(
      id: 'nodira',
      name: 'Nodira Rasulova',
      role: UserRole.client,
      phone: '+998975551237',
      team: 'Zangiota',
      color: 4,
    ),
  ];

  /// Reference to the seeded account [id].
  static UserRef ref(String id) => users.firstWhere((u) => u.id == id).ref;

  /// Log line helper.
  static LogEntry _log(LogKind kind, String userId, DateTime at, [List<String> args = const []]) =>
      LogEntry(kind: kind, user: ref(userId), at: at, args: args);

  /// Seeded tasks covering every status and role scope.
  static List<TaskModel> tasks() => [
    TaskModel(
      id: 'ECO-142',
      title: '50 ta ko‘chat sotish',
      createdBy: ref('jamshid'),
      due: at(3, 18),
      priority: TaskPriority.high,
      status: TaskStatus.prog,
      reward: 1000,
      category: 'Sotuv',
      files: 3,
      expected: '50 ta ko‘chat',
      description: 'Issiqxonadagi archa va qarag‘ay ko‘chatlarini sotish. Har bir sotuvni izohda qayd eting, to‘lov chekini rasmga oling.',
      assignees: [
        TaskAssignee(user: ref('boris'), share: 30, done: 22),
        TaskAssignee(user: ref('nizomjon'), share: 20, done: 10),
      ],
      expenses: [
        ExpenseModel(
          id: 'e1',
          user: ref('boris'),
          note: 'Transport — ko‘chatlarni tashish',
          amount: 200,
          approvedAmount: 180,
          kind: ExpenseKind.transport,
          status: ExpenseStatus.approved,
          at: at(-1, 17, 32),
        ),
        ExpenseModel(
          id: 'e2',
          user: ref('nizomjon'),
          note: 'Qadoqlash materiallari',
          amount: 60,
          kind: ExpenseKind.material,
          hasReceipt: false,
          at: ago(40),
        ),
      ],
      comments: [
        CommentModel(
          user: ref('boris'),
          text: 'Bugun 12 ta sotildi, rasmlarni yukladim. Qolganlari shanba bozorida.',
          at: at(0, 10, 42),
        ),
        CommentModel(user: ref('jamshid'), text: 'Yaxshi. Qarag‘aylarni birinchi navbatda soting.', at: at(0, 11, 5)),
      ],
      log: [
        _log(LogKind.expenseApproved, 'jamshid', at(-1, 19, 10), ['180 \$', '200 \$']),
        _log(LogKind.expense, 'boris', at(-1, 17, 32), ['200 \$']),
        _log(LogKind.started, 'boris', at(-3, 9, 14)),
        _log(LogKind.created, 'jamshid', at(-3, 8, 40)),
      ],
    ),
    TaskModel(
      id: 'ECO-147',
      title: 'Issiqxonadagi ko‘chatlarni sug‘orish',
      createdBy: ref('malika'),
      due: at(0, 18),
      priority: TaskPriority.low,
      status: TaskStatus.prog,
      reward: 40,
      description: '2-issiqxona. Ertalabki va kechki sug‘orish.',
      assignees: [
        TaskAssignee(user: ref('boris')),
        TaskAssignee(user: ref('nizomjon')),
      ],
      log: [_log(LogKind.created, 'malika', at(-2, 9))],
    ),
    TaskModel(
      id: 'ECO-150',
      title: 'Transport xarajatlarini qayd etish',
      createdBy: ref('jamshid'),
      due: at(0, 20),
      reward: 20,
      description: 'Sentabr oyi uchun.',
      assignees: [TaskAssignee(user: ref('boris'))],
      log: [_log(LogKind.created, 'jamshid', at(-1, 9))],
    ),
    TaskModel(
      id: 'ECO-148',
      title: 'Mijozga belgilangan manzilda tashrif',
      createdBy: ref('malika'),
      due: at(1, 11),
      reward: 80,
      description: 'Chilonzor, Bunyodkor 12. Mijoz bilan ekish joyini kelishib oling.',
      assignees: [TaskAssignee(user: ref('boris'))],
      log: [_log(LogKind.created, 'malika', at(0, 8))],
    ),
    TaskModel(
      id: 'ECO-139',
      title: 'Tuproq va o‘g‘it xarid qilish',
      createdBy: ref('jamshid'),
      due: at(1, 12),
      status: TaskStatus.rev,
      reward: 300,
      files: 3,
      description: '20 qop tuproq va 5 qop kompleks o‘g‘it. Chekni biriktiring.',
      result: '20 qop tuproq va 5 qop o‘g‘it omborga tushirildi.',
      submittedAt: ago(15),
      assignees: [TaskAssignee(user: ref('nizomjon'))],
      expenses: [
        ExpenseModel(
          id: 'e3',
          user: ref('nizomjon'),
          note: 'Tuproq 20 qop, o‘g‘it 5 qop',
          amount: 340,
          kind: ExpenseKind.material,
          at: ago(20),
        ),
      ],
      comments: [CommentModel(user: ref('nizomjon'), text: 'Hammasi omborga tushirildi.', at: at(0, 9, 15))],
      log: [_log(LogKind.submitted, 'nizomjon', ago(15)), _log(LogKind.created, 'jamshid', at(-2, 9))],
    ),
    TaskModel(
      id: 'ECO-136',
      title: 'Buyurtmani yetkazishga tayyorlash',
      createdBy: ref('malika'),
      due: at(-2, 17),
      status: TaskStatus.prog,
      reward: 150,
      description: '#2033 buyurtma: 30 ta gul ko‘chati, qadoqlash va yorliqlash.',
      assignees: [
        TaskAssignee(user: ref('azizbek')),
        TaskAssignee(user: ref('nizomjon')),
      ],
      log: [_log(LogKind.created, 'malika', at(-5, 9))],
    ),
    TaskModel(
      id: 'ECO-145',
      title: 'Mijozga o‘simliklarni yetkazib berish',
      createdBy: ref('malika'),
      due: at(0, 16),
      priority: TaskPriority.high,
      reward: 120,
      description: 'Yunusobod tumani, 4-mavze, 17-uy.',
      assignees: [TaskAssignee(user: ref('azizbek'))],
      log: [_log(LogKind.created, 'malika', at(0, 7))],
    ),
    TaskModel(
      id: 'ECO-133',
      title: 'Buyurtma #2029 ni mijozga topshirish',
      createdBy: ref('malika'),
      due: at(-1, 12),
      status: TaskStatus.rev,
      reward: 90,
      files: 3,
      result: 'Buyurtma topshirildi, mijoz imzo qo‘ydi.',
      submittedAt: at(-1, 18, 20),
      assignees: [TaskAssignee(user: ref('azizbek'))],
      log: [_log(LogKind.submitted, 'azizbek', at(-1, 18, 20))],
    ),
    TaskModel(
      id: 'ECO-125',
      title: 'Buyurtma #2031 ni tayyorlash',
      createdBy: ref('malika'),
      due: at(-2, 12),
      status: TaskStatus.rev,
      reward: 60,
      result: 'Qadoqlandi.',
      submittedAt: at(-2, 15),
      assignees: [TaskAssignee(user: ref('boris'))],
      log: [_log(LogKind.submitted, 'boris', at(-2, 15))],
    ),
    TaskModel(
      id: 'ECO-141',
      title: 'Ertalabki sug‘orish va nasos tekshiruvi',
      createdBy: ref('jamshid'),
      due: at(-1, 9),
      status: TaskStatus.done,
      reward: 40,
      assignees: [TaskAssignee(user: ref('boris'))],
      log: [_log(LogKind.done, 'jamshid', at(-1, 12, 30))],
    ),
    TaskModel(
      id: 'ECO-131',
      title: 'Transport xarajatlarini qayd etish (sentabr)',
      createdBy: ref('jamshid'),
      due: at(-4, 18),
      status: TaskStatus.done,
      isPaid: true,
      reward: 50,
      assignees: [TaskAssignee(user: ref('boris'))],
      log: [_log(LogKind.done, 'jamshid', at(-4, 19))],
    ),
    TaskModel(
      id: 'ECO-120',
      title: 'Ko‘chatlarni yangi tuvaklarga o‘tkazish',
      createdBy: ref('jamshid'),
      due: at(-7, 18),
      status: TaskStatus.canc,
      assignees: [TaskAssignee(user: ref('boris'))],
    ),
    TaskModel(
      id: 'ECO-118',
      title: 'Bozorda savdo nuqtasini tayyorlash',
      createdBy: ref('jamshid'),
      due: at(-10, 18),
      status: TaskStatus.fail,
      description: 'Sabab: ruxsat berilmadi',
      assignees: [TaskAssignee(user: ref('boris'))],
    ),
    TaskModel(
      id: 'ECO-152',
      title: 'Issiqxona shamollatishni tekshirish',
      createdBy: ref('jamshid'),
      due: at(2, 10),
      reward: 30,
      assignees: [TaskAssignee(user: ref('dilshod'))],
      log: [_log(LogKind.created, 'jamshid', at(0, 9))],
    ),
  ];

  /// Seeded client requests.
  static List<RequestModel> requests() => [
    RequestModel(
      id: 'R-2041',
      client: ref('gulnora'),
      title: 'Hovliga 20 ta archa ekish',
      createdAt: at(-1, 17, 5),
      kind: RequestKind.planting,
      status: RequestStatus.planned,
      address: 'Yunusobod tumani, 4-mavze, 17-uy',
      date: at(5),
      slot: '09:00–12:00',
      assignee: ref('azizbek'),
      detail: 'Uy oldidagi yo‘lak bo‘ylab, har 2 metrda. Tuproq tayyor.',
      comments: [
        CommentModel(
          user: ref('malika'),
          text: 'Archa ko‘chatlari tayyor. 14-oktabr ertalab boramiz.',
          at: at(0, 10, 21),
        ),
        CommentModel(user: ref('gulnora'), text: 'Rahmat! Darvoza ochiq bo‘ladi.', at: at(0, 10, 40)),
      ],
    ),
    RequestModel(
      id: 'R-2044',
      client: ref('gulnora'),
      title: 'Gul ko‘chatlari — 30 ta',
      createdAt: ago(120),
      address: 'Yunusobod tumani, 4-mavze, 17-uy',
    ),
    RequestModel(
      id: 'R-2033',
      client: ref('gulnora'),
      title: 'Gul ko‘chatlarini yetkazib berish',
      createdAt: at(-14),
      status: RequestStatus.done,
      address: 'Mirobod',
      date: at(-7),
      assignee: ref('azizbek'),
    ),
    RequestModel(
      id: 'R-2040',
      client: ref('otabek'),
      title: 'Bog‘ parvarishi',
      createdAt: at(-2),
      kind: RequestKind.care,
      address: 'Chilonzor tumani',
    ),
  ];

  /// Builds one inbox entry.
  static NotificationModel _n(
    String kindName,
    String to,
    DateTime at, {
    List<String> t = const [],
    List<String> b = const [],
    bool read = false,
  }) => NotificationModel(
    id: 'n_${kindName}_${to}_${at.millisecondsSinceEpoch}',
    userId: to,
    kind: NotificationKind.fromJson(kindName),
    at: at,
    titleArgs: t,
    bodyArgs: b,
    isRead: read,
  );

  /// Seeded inbox entries for every role.
  static List<NotificationModel> notifications() => [
    for (final to in ['jamshid', 'malika']) ...[
      _n('review', to, ago(15), b: ['Nizomjon', 'Tuproq va o‘g‘it xarid qilish']),
      _n('expense', to, ago(40), t: ['60 \$'], b: ['Qadoqlash materiallari', 'ECO-142']),
      _n('overdue', to, at(0, 9), b: ['Buyurtmani yetkazishga tayyorlash', 'Azizbek, Nizomjon']),
      _n('comment', to, at(0, 10, 42), t: ['Boris'], b: ['Bugun 12 ta sotildi, rasmlarni yukladim.'], read: true),
      _n('request', to, at(-1, 17, 5), b: ['Gulnora Saidova', 'Hovliga 20 ta archa ekish'], read: true),
      _n('status', to, at(-1, 12, 30), b: ['ECO-141', 'Ertalabki sug‘orish'], read: true),
    ],
    _n('newTask', 'boris', ago(20), b: ['Malika', 'Mijozga belgilangan manzilda tashrif']),
    _n('comment', 'boris', at(0, 11, 5), t: ['Jamshid'], b: ['Qarag‘aylarni birinchi navbatda soting.'], read: true),
    _n('dueSoon', 'boris', at(0, 9), b: ['Issiqxonadagi ko‘chatlarni sug‘orish', 'bugun 18:00'], read: true),
    _n('approved', 'boris', at(-1, 12, 30), b: ['ECO-141', '40 \$'], read: true),
    _n('expenseApproved', 'boris', at(-1, 19, 10), t: ['180 \$'], b: ['200 \$'], read: true),
    _n('returned', 'boris', at(-1, 10, 15), b: ['Buyurtma #2031', 'Qadoq yorliqlari yo‘q'], read: true),
    _n('requestPlanned', 'gulnora', at(0, 10, 20), b: ['R-2041', '14-oktabr, 09:00–12:00', 'Azizbek']),
    _n(
      'requestMessage',
      'gulnora',
      at(0, 10, 21),
      b: ['Malika', 'Archa ko‘chatlari tayyor. 14-oktabr ertalab boramiz.'],
      read: true,
    ),
    _n('requestAccepted', 'gulnora', at(-1, 17, 5), b: ['R-2041', 'Hovliga 20 ta archa ekish'], read: true),
    _n('requestDone', 'gulnora', at(-7, 15, 40), b: ['R-2033', 'Gul ko‘chatlari yetkazib berildi'], read: true),
    _n('newTask', 'nizomjon', ago(60), b: ['Malika', 'Buyurtmani yetkazishga tayyorlash']),
    _n('newTask', 'azizbek', ago(90), b: ['Malika', 'Mijozga o‘simliklarni yetkazib berish']),
  ];
}
