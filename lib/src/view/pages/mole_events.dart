import 'package:flutter/material.dart';
import 'package:mole_app/src/model/mole_model.dart';
import 'package:mole_app/src/model/mole_event.dart';
import 'package:intl/intl.dart';

class MoleEventWidget extends StatelessWidget {
  final MoleModel model;
  const MoleEventWidget(this.model,{super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 48, child: ElevatedButton(
            onPressed: () => model.switchLobbyPage(MolePage.lobby),
            child: Row(children: [
              Icon(Icons.keyboard_return),Text(" Back to Lobby")]
            ))),
        Expanded(child: EventCalendarWidget(model.events)),
      ],
    );
  }
}

class EventCalendarWidget extends StatefulWidget {
  final List<MoleEvent> events;

  const EventCalendarWidget(this.events, {super.key});

  @override
  State<EventCalendarWidget> createState() => _EventCalendarWidgetState();
}

class _EventCalendarWidgetState extends State<EventCalendarWidget> {
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
  }

  int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  void goToPreviousMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month - 1);
    });
  }

  void goToNextMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month + 1);
    });
  }

  List<MoleEvent> getEventsForDate(int day) {
    return widget.events.where((event) {
      final localTime = event.time.toLocal();
      return localTime.day == day &&
          localTime.month == currentDate.month &&
          localTime.year == currentDate.year;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(currentDate);
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final totalDays = daysInMonth(currentDate);
    final firstDay = firstDayOfMonth(currentDate);

    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f172a),
              Color(0xFF581c87),
              Color(0xFF0f172a),
            ],
          ),
        ),

          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mole Meets',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'catch the next mole gathering',
                  style: TextStyle(color: Color(0xFFe9d5ff), fontSize: 14),
                ),
                SizedBox(height: 32),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCalendar(
                          monthName,
                          dayNames,
                          totalDays,
                          firstDay,
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildUpcomingEvents(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      );
  }

  Widget _buildCalendar(String monthName, List<String> dayNames,
      int totalDays, int firstDay) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1e293b).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFa855f7).withOpacity(0.2)),
      ),
      child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: goToPreviousMonth,
                    icon: Icon(Icons.chevron_left, color: Color(0xFFc084fc)),
                  ),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: goToNextMonth,
                    icon: Icon(Icons.chevron_right, color: Color(0xFFc084fc)),
                  ),
                ],
              ),
              SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                childAspectRatio: 1.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: dayNames
                    .map((day) => Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFd8b4fe),
                    ),
                  ),
                ))
                    .toList(),
              ),
              SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: firstDay + totalDays,
                  itemBuilder: (context, index) {
                    if (index < firstDay) {
                      return Container();
                    }

                    final day = index - firstDay + 1;
                    final dayEvents = getEventsForDate(day);
                    final hasEvents = dayEvents.isNotEmpty;

                    return Container(
                      decoration: BoxDecoration(
                        gradient: hasEvents
                            ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF9333ea),
                            Color(0xFF7e22ce),
                          ],
                        )
                            : null,
                        color: hasEvents ? null : Color(0xFF334155).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: hasEvents
                            ? Border.all(color: Color(0xFFa855f7))
                            : Border.all(color: Color(0xFFa855f7).withOpacity(0.1)),
                        boxShadow: hasEvents
                            ? [
                          BoxShadow(
                            color: Color(0xFFa855f7).withOpacity(0.3),
                            blurRadius: 8,
                          )
                        ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: hasEvents ? Colors.white : Color(0xFFd1d5db),
                              ),
                            ),
                          ),
                          if (hasEvents)
                            Spacer(),
                          if (hasEvents)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Color(0xFFfcd34d),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFfcd34d).withOpacity(0.5),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          SizedBox(height: 4),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    final sortedEvents = List<MoleEvent>.from(widget.events)
      ..sort((a, b) => a.time.compareTo(b.time));

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1e293b).withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFa855f7).withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: sortedEvents.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  MoleEvent event = sortedEvents[index]; //print("Event Time: ${event.time}");
                  return Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF475569).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFa855f7).withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.desc,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 12, color: Color(0xFFd8b4fe)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${DateFormat('MMM dd').format(event.time)} at ${DateFormat('HH:mm').format(event.time)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFd8b4fe),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 12, color: Color(0xFFd8b4fe)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  DateTime.now().timeZoneName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFd8b4fe),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
