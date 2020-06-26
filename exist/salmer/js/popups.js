// Function used to show notes
var dialog_opts = {
  title: __[loc]('Note'),
  autoOpen: false,
  show: {
    effect: "fade",
    duration: 300
  },
  hide: {
    effect: "fade",
    duration: 300
  },
  width: 320,
  minHeight: 80,
  resizable: false,
  draggable: false,
};

function toggle(){} // onclick="toggle" handlers are written directly in the XML, and thus we can't unregister them. Therefore define a toggle() function so we don't get errors of undefined.

function activateNotesInLeftColumn() {
  // activateNotes("note", "#notelink", __[loc]("Kommentar"));
  activateNotes("appnote", "#appnotelink", __[loc]("Tekstkritik"));
  // activateNotes("persName", "#persNamelink", __[loc]("Person"));
  // activateNotes("fictionalpersName", "#fictionalpersNamelink", __[loc]("Litterær figur"));
  // activateNotes("bibl", "#bibllink", __[loc]("Værk"));
  // activateNotes("placeName", "#placeNamelink", __[loc]("Sted"));
  // activateNotes("publicationName", "#publicationNamelink", __[loc]("Værk"));
}

function activateNotesInRightColumn() {
  var css_class_no_dot = "publicationReferenceInNote";
  var css_class = "." + css_class_no_dot
  var css_id = "#";

  // destroy any old dialogs left over from previous page
  // in case of AJAX pagination
  // $('[id^="dialogn"]').dialog('destroy');

  var notes = $(css_class);

  for (var i = 0; i < notes.length; i++) {
    current_note_no = notes[i].id;
    note_contents_id = "#" + current_note_no;
    var note_link_id = css_id + current_note_no;

    $(note_link_id).mouseover(function(event) {
      note_link_id = '#dialog' + this.id.replace(css_class_no_dot, '');

      $(note_link_id).dialog('open');
      // var x = jQuery(this).position().left + jQuery(this).outerWidth();
      // var y = jQuery(this).position().top - jQuery(document).scrollTop();
      jQuery(note_link_id).dialog('option', 'position', {
        my: "left top+13",
        at: "left top",
        of: event,
        offset: "20 200",
        collision: "none",
        resizable: false,
        draggable: false
      });
    });
    $('#' + current_note_no).mouseout(function(event) {
      $(note_link_id).dialog("close");
    });
  }
}

function activateNotes(css_base_class, css_id, title) {
  var css_class = '.' + css_base_class + 'contents';
  var css_class_no_dot = css_class.replace('.', '');

  // destroy any old dialogs left over from previous page
  // in case of AJAX pagination
  $(".ui-dialog." + css_base_class + 'contentsbox').find('.ui-dialog-content').dialog('destroy');

  var notes = $(css_class);
  for (var i = 0; i < notes.length; i++) {
    current_note_no = notes[i].id;
    note_contents_id = "#" + current_note_no;
    note_link_id = css_id + current_note_no;
    dialog_opts.title = title;
    if (title == __[loc]("Kommentar") && !note_contents_id.startsWith('#Note')) {
      dialog_opts.title = __[loc]("Forfatterens note");
    }
    dialog_opts.dialogClass = css_class.slice(1) + "box"

    note_box = $(note_contents_id).dialog(dialog_opts);
    $(note_link_id).mouseover({
        controller: css_base_class,
        note_box: note_box,
        note_contents_id: note_contents_id
      },
      dialogPosition);
    $(note_link_id).mouseout(function(event) {
      if($('[data-toggle="' + css_base_class + '"]').prop('checked')) {
        $('.ui-dialog-content').dialog("close");
      }
    });
  }
}

function dialogPosition(event) {
  // only open dialogs that have their control switched on
  if($('[data-toggle="' + event.data.controller + '"]').prop('checked')) {
    event.data.note_box.dialog("option", "position", {
      my: "left top+13",
      at: "left top",
      of: event,
      offset: "20 200",
      collision: "none",
      resizable: false,
      draggable: false
    });
    $(".ui-dialog-content").dialog().dialog("close");
    $(event.data.note_contents_id).dialog("open");
  }
}

$(window).on('load', function() {
  activateNotesInLeftColumn();
  activateNotesInRightColumn();
});
