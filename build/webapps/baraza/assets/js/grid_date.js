    var MyDateField = function(config) {
        jsGrid.Field.call(this, config);
    };

    MyDateField.prototype = new jsGrid.Field({

        css: "date-field",            // redefine general property 'css'
        align: "center",              // redefine general property 'align'

        myCustomProperty: "datecp",      // custom property

        sorter: function(date1, date2) {
            return new Date(date1) - new Date(date2);
        },

        itemTemplate: function(value) {
			var dt = '';
			if(value) dt = $.datepicker.formatDate('dd M yy', new Date(value));
            return dt;
        },

        insertTemplate: function(value) {
            return this._insertPicker = $("<input>").datepicker({ defaultDate: new Date() });
        },

		editTemplate: function (value) {
			this._editPicker = $("<input>").datepicker({ defaultDate: new Date(value)});
			this._editPicker.datepicker("setDate", new Date(value));

			return this._editPicker;
        },

        insertValue: function() {
			var dt = null;
			if(this._insertPicker.datepicker("getDate") != null) dt = $.datepicker.formatDate('dd-mm-yy', this._insertPicker.datepicker("getDate"));
            return dt;
        },

        editValue: function() {
			var dt = null;
			if(this._editPicker.datepicker("getDate") != null) dt = $.datepicker.formatDate('dd-mm-yy', this._editPicker.datepicker("getDate"));
            return dt;
        }
    });

    jsGrid.fields.date = MyDateField;


