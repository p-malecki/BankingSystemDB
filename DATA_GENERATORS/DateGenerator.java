import java.time.LocalDate;
import java.util.GregorianCalendar;
import java.util.concurrent.ThreadLocalRandom;

public class DateGenerator{
    public static String randomDate(){
        GregorianCalendar gc = new GregorianCalendar();
        int year = randBetween(2007, 2022);
        gc.set(gc.YEAR, year);
        int dayOfYear = randBetween(1, gc.getActualMaximum(gc.DAY_OF_YEAR));
        gc.set(gc.DAY_OF_YEAR, dayOfYear);
        return (gc.get(gc.YEAR) + "-" + (gc.get(gc.MONTH) + 1) + "-" + gc.get(gc.DAY_OF_MONTH));
    }

    public static String randomDateBetween(String left, String right){
        LocalDate startDate = LocalDate.parse(left); //start date
        long start = startDate.toEpochDay();

        LocalDate endDate = LocalDate.parse(right); //end date
        long end = endDate.toEpochDay();

        if(startDate.equals(endDate))
            return endDate.toString();

        long randomEpochDay = ThreadLocalRandom.current().longs(start, end).findAny().getAsLong();
        return LocalDate.ofEpochDay(randomEpochDay).toString();
    }

    public static int randBetween(int start, int end){
        return start + (int) Math.round(Math.random() * (end - start));
    }

    public static String format(String date){
        String[] dateSplit = date.split("-");
        date = dateSplit[2] + "-" + dateSplit[1] + "-" + dateSplit[0];
        return date;
    }

    public static void main(String[] args){
        System.out.println(randomDate());
    }
}
